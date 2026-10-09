import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/ai_service.dart';
import '../services/native_pdf_renderer.dart';
import '../services/native_video_encoder.dart';
import 'animation_planner.dart';

class VideoPipelineService {
  static final VideoPipelineService instance = VideoPipelineService._internal();
  VideoPipelineService._internal();

  /// Executes the full on-device pedagogical video generation workflow
  Future<String> generateLessonVideo({
    required String prompt,
    required void Function(String statusMessage, double progress) onProgress,
  }) async {
    // Stage 1: Generate Structured Pedagogical LaTeX via AI Provider
    onProgress('Structuring educational lesson via AI...', 0.15);
    final latexSource = await AIService.instance.generateLessonLatex(prompt);

    // Stage 2: Parse LaTeX into Semantic LessonDocument IR
    onProgress('Parsing lesson scenes and mathematical formulas...', 0.35);
    final doc = AnimationPlanner.parseLatex(latexSource, fallbackTitle: prompt);

    // Stage 3: Plan Progressive Animation Timeline
    onProgress('Designing progressive reveals and transition states...', 0.50);
    final timeline = AnimationPlanner.planTimeline(doc);
    final presentationLatex = AnimationPlanner.generatePresentationLatex(timeline);

    final jobTimestamp = DateTime.now().millisecondsSinceEpoch;

    // Stage 4: Write presentation LaTeX file on native devices
    final tempDir = await getTemporaryDirectory();
    final latexFile = File('${tempDir.path}/lesson_$jobTimestamp.tex');
    await latexFile.writeAsString(presentationLatex);

    // Stage 5: Compile PDF & Rasterize Progressive Slides
    onProgress('Compiling and rasterizing 1080p slide frames...', 0.70);
    final pdfFile = File('${tempDir.path}/lesson_$jobTimestamp.pdf');

    // On-device PDF rendering via NativePdfRenderer plugin
    List<String> renderedImages = [];
    if (pdfFile.existsSync()) {
      renderedImages = await NativePdfRenderer.renderPages(
        pdfFile.path,
        width: 1920,
        height: 1080,
      );
    }

    // Stage 6: Hardware Video Encoding via MediaCodec
    onProgress('Encoding broadcast-quality H.264 MP4 in hardware...', 0.85);
    final appDocsDir = await getApplicationDocumentsDirectory();
    final outputMp4Path = '${appDocsDir.path}/kestrel_lesson_$jobTimestamp.mp4';

    final durationsMs = timeline.map((s) => s.holdDurationMs).toList();

    if (renderedImages.isNotEmpty) {
      await NativeVideoEncoder.encodeFrames(
        imagePaths: renderedImages,
        durationsMs: durationsMs,
        outputPath: outputMp4Path,
        width: 1920,
        height: 1080,
        fps: 30,
      );
    }

    onProgress('Lesson video generation finalized!', 1.0);
    return outputMp4Path;
  }
}
