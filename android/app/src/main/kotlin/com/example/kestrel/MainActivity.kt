package com.example.kestrel

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Native Hardware PDF Renderer Plugin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PdfRendererPlugin.CHANNEL)
            .setMethodCallHandler(PdfRendererPlugin(applicationContext))

        // Register Native Hardware MediaCodec Video Recorder Plugin
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MediaCodecVideoRecorder.CHANNEL)
            .setMethodCallHandler(MediaCodecVideoRecorder(applicationContext))
    }
}
