import '../services/ai_service.dart';
import 'animation_planner.dart';

class VideoPipelineService {
  static final VideoPipelineService instance = VideoPipelineService._internal();
  VideoPipelineService._internal();

  /// Web simulation of pedagogical video generation
  Future<String> generateLessonVideo({
    required String prompt,
    required void Function(String statusMessage, double progress) onProgress,
  }) async {
    onProgress('Structuring educational lesson via AI...', 0.20);
    final latexSource = await AIService.instance.generateLessonLatex(prompt);

    onProgress('Parsing lesson scenes and mathematical formulas...', 0.45);
    final doc = AnimationPlanner.parseLatex(latexSource, fallbackTitle: prompt);

    onProgress('Designing progressive reveals and transition states...', 0.70);
    final timeline = AnimationPlanner.planTimeline(doc);

    onProgress('Simulating presentation timeline on web...', 0.90);
    await Future.delayed(const Duration(milliseconds: 500));

    onProgress('Lesson presentation ready for review!', 1.0);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'web_preview_lesson_$timestamp (Total slides: ${timeline.length})';
  }
}
