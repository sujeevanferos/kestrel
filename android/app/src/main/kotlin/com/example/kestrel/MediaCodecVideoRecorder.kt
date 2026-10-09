package com.example.kestrel

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.view.Surface
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.util.Locale
import java.util.concurrent.Executors

class MediaCodecVideoRecorder(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.kestrel.video_recorder"
        private const val MIME_TYPE = MediaFormat.MIMETYPE_VIDEO_AVC // H.264
        private const val I_FRAME_INTERVAL = 1 // 1 second between keyframes
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var textToSpeech: TextToSpeech? = null

    init {
        mainHandler.post {
            textToSpeech = TextToSpeech(context) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    textToSpeech?.language = Locale.US
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "synthesizeNarration" -> {
                val text = call.argument<String>("text")
                val outputPath = call.argument<String>("outputPath")
                if (text == null || outputPath == null) {
                    result.error("INVALID_ARGS", "Missing text or outputPath", null)
                    return
                }

                val file = File(outputPath)
                file.parentFile?.mkdirs()
                val utteranceId = "kestrel_narration_${System.currentTimeMillis()}"
                val params = Bundle()

                val ret = textToSpeech?.synthesizeToFile(text, params, file, utteranceId)
                if (ret == TextToSpeech.SUCCESS) {
                    result.success(outputPath)
                } else {
                    result.error("TTS_ERROR", "Failed to synthesize speech to file", null)
                }
            }
            "encodeFrames" -> {
                val imagePaths = call.argument<List<String>>("imagePaths")
                val durationsMs = call.argument<List<Int>>("durationsMs")
                val audioPath = call.argument<String>("audioPath")
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
                        encodeVideo(imagePaths, durationsMs, audioPath, outputPath, width, height, fps, bitrate)
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
        audioPath: String?,
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

        val codec = MediaCodec.createEncoderByType(MIME_TYPE)
        codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface: Surface = codec.createInputSurface()
        codec.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var videoTrackIndex = -1
        var muxerStarted = false

        // Check for audio track if provided
        var audioTrackIndex = -1
        var audioExtractor: MediaExtractor? = null
        if (audioPath != null && File(audioPath).exists()) {
            try {
                audioExtractor = MediaExtractor().apply {
                    setDataSource(audioPath)
                    for (i in 0 until trackCount) {
                        val trackFormat = getTrackFormat(i)
                        val mime = trackFormat.getString(MediaFormat.KEY_MIME) ?: ""
                        if (mime.startsWith("audio/")) {
                            selectTrack(i)
                            audioTrackIndex = muxer.addTrack(trackFormat)
                            break
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        val bufferInfo = MediaCodec.BufferInfo()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        var presentationTimeUs = 0L

        try {
            for (idx in imagePaths.indices) {
                val imgPath = imagePaths[idx]
                val durationMs = durationsMs.getOrElse(idx) { 3000 }
                val totalFramesForSlide = (durationMs * fps) / 1000
                val frameDurationUs = 1_000_000L / fps

                val bmp = BitmapFactory.decodeFile(imgPath) ?: continue

                for (frame in 0 until totalFramesForSlide) {
                    val canvas: Canvas = inputSurface.lockHardwareCanvas()
                    canvas.drawColor(Color.BLACK)

                    val scale = minOf(width.toFloat() / bmp.width, height.toFloat() / bmp.height)
                    val dx = (width - bmp.width * scale) / 2f
                    val dy = (height - bmp.height * scale) / 2f

                    canvas.save()
                    canvas.translate(dx, dy)
                    canvas.scale(scale, scale)
                    canvas.drawBitmap(bmp, 0f, 0f, paint)
                    canvas.restore()

                    inputSurface.unlockCanvasAndPost(canvas)

                    presentationTimeUs += frameDurationUs
                    drainEncoder(codec, bufferInfo, muxer, false) { index ->
                        videoTrackIndex = index
                        if (!muxerStarted) {
                            muxer.start()
                            muxerStarted = true
                        }
                    }
                }
                bmp.recycle()
            }

            codec.signalEndOfInputStream()
            drainEncoder(codec, bufferInfo, muxer, true) { index ->
                videoTrackIndex = index
                if (!muxerStarted) {
                    muxer.start()
                    muxerStarted = true
                }
            }

            // Mux audio samples if audio track exists
            if (audioExtractor != null && audioTrackIndex != -1 && muxerStarted) {
                val audioBuffer = ByteBuffer.allocate(128 * 1024)
                val audioInfo = MediaCodec.BufferInfo()
                while (true) {
                    val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)
                    if (sampleSize < 0) break
                    audioInfo.offset = 0
                    audioInfo.size = sampleSize
                    audioInfo.presentationTimeUs = audioExtractor.sampleTime
                    audioInfo.flags = audioExtractor.sampleFlags
                    muxer.writeSampleData(audioTrackIndex, audioBuffer, audioInfo)
                    audioExtractor.advance()
                }
            }

        } finally {
            codec.stop()
            codec.release()
            inputSurface.release()
            audioExtractor?.release()
            if (muxerStarted) {
                muxer.stop()
            }
            muxer.release()
        }
    }

    private fun drainEncoder(
        codec: MediaCodec,
        bufferInfo: MediaCodec.BufferInfo,
        muxer: MediaMuxer,
        endOfStream: Boolean,
        onFormatChanged: (Int) -> Unit
    ) {
        val timeoutUs = if (endOfStream) 10000L else 0L
        while (true) {
            val status = codec.dequeueOutputBuffer(bufferInfo, timeoutUs)
            when {
                status == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                status == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val newFormat = codec.outputFormat
                    val trackIndex = muxer.addTrack(newFormat)
                    onFormatChanged(trackIndex)
                }
                status >= 0 -> {
                    val encodedData = codec.getOutputBuffer(status) ?: continue
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size != 0) {
                        encodedData.position(bufferInfo.offset)
                        encodedData.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(0, encodedData, bufferInfo)
                    }
                    codec.releaseOutputBuffer(status, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        break
                    }
                }
            }
        }
    }
}
