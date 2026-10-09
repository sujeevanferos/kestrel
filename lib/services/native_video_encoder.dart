import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeVideoEncoder {
  static const MethodChannel _channel = MethodChannel('com.kestrel.video_recorder');

  /// Encodes a sequence of slide images into a hardware H.264 MP4 file using Android MediaCodec
  static Future<String> encodeFrames({
    required List<String> imagePaths,
    required List<int> durationsMs,
    required String outputPath,
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
