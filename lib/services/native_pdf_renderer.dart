import 'dart:io';
import 'package:flutter/services.dart';

class NativePdfRenderer {
  static const MethodChannel _channel = MethodChannel('com.kestrel.pdf_renderer');

  /// Renders all pages of a PDF file into 1080p PNG images using Android hardware PdfRenderer
  static Future<List<String>> renderPages(
    String pdfPath, {
    int width = 1920,
    int height = 1080,
  }) async {
    if (!Platform.isAndroid) {
      // Desktop / fallback simulation for testing
      return [];
    }

    try {
      final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>(
        'renderPages',
        {
          'pdfPath': pdfPath,
          'width': width,
          'height': height,
        },
      );
      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      throw Exception('PDF Rendering failed: ${e.message}');
    }
  }

  /// Gets the total page count of a PDF file
  static Future<int> getPageCount(String pdfPath) async {
    if (!Platform.isAndroid) return 0;
    try {
      final int? count = await _channel.invokeMethod<int>(
        'getPageCount',
        {'pdfPath': pdfPath},
      );
      return count ?? 0;
    } on PlatformException catch (e) {
      throw Exception('Failed to get PDF page count: ${e.message}');
    }
  }
}
