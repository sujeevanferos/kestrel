package com.example.kestrel

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MediaCodecVideoRecorder(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.kestrel.video_recorder"
        private const val MIME_TYPE = MediaFormat.MIMETYPE_VIDEO_AVC // H.264
        private const val I_FRAME_INTERVAL = 1 // 1 second between keyframes
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "encodeFrames" -> {
                val imagePaths = call.argument<List<String>>("imagePaths")
                val durationsMs = call.argument<List<Int>>("durationsMs")
                val outputPath = call.argument<String>("outputPath")
                val width = call.argument<Int>("width") ?: 1920
                val height = call.argument<Int>("height") ?: 1080
                val fps = call.argument<Int>("fps") ?: 30
                val bitrate = call.argument<Int>("bitrate") ?: 4_000_000 // 4 Mbps for 1080p

                if (imagePaths == null || durationsMs == null || outputPath == null) {
                    result.error("INVALID_ARGS", "Missing required arguments", null)
                    return
                }

                executor.execute {
                    try {
                        encodeVideo(imagePaths, durationsMs, outputPath, width, height, fps, bitrate)
                        mainHandler.post {
                            result.success(outputPath)
                        }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("ENCODE_ERROR", e.localizedMessage, null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun encodeVideo(
        imagePaths: List<String>,
        durationsMs: List<Int>,
        outputPath: String,
        width: Int,
        height: Int,
        fps: Int,
        bitrate: Int
    ) {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()
        if (outputFile.exists()) outputFile.delete()

        val format = MediaFormat.createVideoFormat(MIME_TYPE, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, I_FRAME_INTERVAL)
        }

        val encoder = MediaCodec.createEncoderByType(MIME_TYPE)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface: Surface = encoder.createInputSurface()
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var trackIndex = -1
        var muxerStarted = false

        val bufferInfo = MediaCodec.BufferInfo()
        val frameDurationUs = (1_000_000L / fps)
        var presentationTimeUs = 0L

        val paint = Paint(Paint.FILTER_BITMAP_FLAG)

        try {
            for (idx in imagePaths.indices) {
                val imgPath = imagePaths[idx]
                val durationMs = if (idx < durationsMs.size) durationsMs[idx] else 2000
                val frameCountForSlide = (durationMs * fps / 1000).coerceAtLeast(1)

                val bitmap = BitmapFactory.decodeFile(imgPath) ?: continue

                for (f in 0 until frameCountForSlide) {
                    val canvas: Canvas = inputSurface.lockCanvas(null)
                    try {
                        canvas.drawColor(Color.WHITE)
                        canvas.drawBitmap(bitmap, 0f, 0f, paint)
                    } finally {
                        inputSurface.unlockCanvasAndPost(canvas)
                    }

                    drainEncoder(encoder, bufferInfo, muxer, trackIndex, false) { newTrackIndex ->
                        trackIndex = newTrackIndex
                        muxerStarted = true
                    }

                    presentationTimeUs += frameDurationUs
                }

                bitmap.recycle()
            }

            // Signal End of Stream
            encoder.signalEndOfInputStream()
            drainEncoder(encoder, bufferInfo, muxer, trackIndex, true) { newTrackIndex ->
                trackIndex = newTrackIndex
                muxerStarted = true
            }

        } finally {
            try {
                encoder.stop()
                encoder.release()
                inputSurface.release()
                if (muxerStarted) {
                    muxer.stop()
                    muxer.release()
                }
            } catch (_: Exception) {}
        }
    }

    private fun drainEncoder(
        encoder: MediaCodec,
        bufferInfo: MediaCodec.BufferInfo,
        muxer: MediaMuxer,
        currentTrackIndex: Int,
        endOfStream: Boolean,
        onMuxerStart: (Int) -> Unit
    ) {
        var trackIdx = currentTrackIndex
        val timeoutUs = 10_000L

        while (true) {
            val status = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            if (status == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (status == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                val newFormat = encoder.outputFormat
                trackIdx = muxer.addTrack(newFormat)
                muxer.start()
                onMuxerStart(trackIdx)
            } else if (status >= 0) {
                val encodedData = encoder.getOutputBuffer(status) ?: continue

                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                    bufferInfo.size = 0
                }

                if (bufferInfo.size != 0 && trackIdx >= 0) {
                    encodedData.position(bufferInfo.offset)
                    encodedData.limit(bufferInfo.offset + bufferInfo.size)
                    muxer.writeSampleData(trackIdx, encodedData, bufferInfo)
                }

                encoder.releaseOutputBuffer(status, false)

                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    break
                }
            }
        }
    }
}
