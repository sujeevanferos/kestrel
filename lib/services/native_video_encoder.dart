import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeVideoEncoder {
  static const MethodChannel _channel = MethodChannel('com.kestrel.video_recorder');

  /// Synthesizes speech narration offline to a local audio file via Android TTS
  static Future<String?> synthesizeNarration({
    required String text,
    required String outputPath,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMethod<String>(
        'synthesizeNarration',
        {
          'text': text,
          'outputPath': outputPath,
        },
      );
    } catch (_) {
      return null;
    }
  }

  /// Encodes a sequence of slide images into a hardware H.264 MP4 file using Android MediaCodec + Audio
  static Future<String> encodeFrames({
    required List<String> imagePaths,
    required List<int> durationsMs,
    required String outputPath,
    String? audioPath,
    int width = 1920,
    int height = 1080,
    int fps = 30,
    int bitrate = 4000000,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // Fallback simulation for non-Android targets
      return outputPath;
    }

    try {
      final String? result = await _channel.invokeMethod<String>(
        'encodeFrames',
        {
          'imagePaths': imagePaths,
          'durationsMs': durationsMs,
          'audioPath': audioPath,
          'outputPath': outputPath,
          'width': width,
          'height': height,
          'fps': fps,
          'bitrate': bitrate,
        },
      );
      return result ?? outputPath;
    } on PlatformException catch (e) {
      throw Exception('Hardware video encoding failed: ${e.message}');
    }
  }
}
