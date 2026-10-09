package com.example.kestrel

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class PdfRendererPlugin(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.kestrel.pdf_renderer"
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "renderPages" -> {
                val pdfPath = call.argument<String>("pdfPath")
                val width = call.argument<Int>("width") ?: 1920
                val height = call.argument<Int>("height") ?: 1080

                if (pdfPath == null) {
                    result.error("INVALID_ARGS", "pdfPath cannot be null", null)
                    return
                }

                executor.execute {
                    try {
                        val file = File(pdfPath)
                        if (!file.exists()) {
                            mainHandler.post {
                                result.error("FILE_NOT_FOUND", "PDF file not found at $pdfPath", null)
                            }
                            return@execute
                        }

                        val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                        val renderer = PdfRenderer(pfd)
                        val pageCount = renderer.pageCount
                        val outputPaths = ArrayList<String>()

                        val outputDir = File(context.cacheDir, "pdf_renders_${System.currentTimeMillis()}")
                        outputDir.mkdirs()

                        for (i in 0 until pageCount) {
                            val page = renderer.openPage(i)
                            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            bitmap.eraseColor(Color.WHITE)
                            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            page.close()

                            val outFile = File(outputDir, "page_$i.png")
                            FileOutputStream(outFile).use { out ->
                                bitmap.compress(Bitmap.CompressFormat.PNG, 95, out)
                            }
                            bitmap.recycle()
                            outputPaths.add(outFile.absolutePath)
                        }

                        renderer.close()
                        pfd.close()

                        mainHandler.post {
                            result.success(outputPaths)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("RENDER_ERROR", e.localizedMessage, null)
                        }
                    }
                }
            }
            "getPageCount" -> {
                val pdfPath = call.argument<String>("pdfPath")
                if (pdfPath == null) {
                    result.error("INVALID_ARGS", "pdfPath cannot be null", null)
                    return
                }

                try {
                    val file = File(pdfPath)
                    val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                    val renderer = PdfRenderer(pfd)
                    val count = renderer.pageCount
                    renderer.close()
                    pfd.close()
                    result.success(count)
                } catch (e: Exception) {
                    result.error("COUNT_ERROR", e.localizedMessage, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
