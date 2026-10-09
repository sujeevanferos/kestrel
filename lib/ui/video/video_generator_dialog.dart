import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/ai_service.dart';
import '../../video/video_pipeline_service.dart';

class VideoGeneratorDialog extends StatefulWidget {
  final void Function(String videoPath, String title)? onMountToWhiteboard;

  const VideoGeneratorDialog({super.key, this.onMountToWhiteboard});

  @override
  State<VideoGeneratorDialog> createState() => _VideoGeneratorDialogState();
}

class _VideoGeneratorDialogState extends State<VideoGeneratorDialog> {
  final TextEditingController _promptCtrl = TextEditingController();
  bool _isGenerating = false;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  String? _generatedVideoPath;

  static const List<String> _presets = [
    'Derivation of Quadratic Formula',
    'Kepler\'s Laws of Planetary Motion',
    'Wave Interference and Superposition',
    'Bernoulli\'s Principle in Fluid Dynamics',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    if (!AIService.instance.hasValidKey) {
      setState(() {
        _errorMessage = 'Please configure your Gemini or Grok API key in Settings first.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.05;
      _statusMessage = 'Initializing pedagogical pipeline...';
      _errorMessage = null;
      _generatedVideoPath = null;
    });

    try {
      final outputPath = await VideoPipelineService.instance.generateLessonVideo(
        prompt: prompt,
        onProgress: (status, p) {
          if (mounted) {
            setState(() {
              _statusMessage = status;
              _progress = p;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 1.0;
          _generatedVideoPath = outputPath;
          _statusMessage = 'Lesson video generated successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7F4EE), // Warm parchment
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.video, size: 22, color: Color(0xFF1B1C1E)),
                const SizedBox(width: 12),
                const Text(
                  'LaTeX Video Generator',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1C1E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 28),

            // Topic prompt field
            const Text(
              'Educational Topic or Derivation Prompt',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4E57),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              enabled: !_isGenerating,
              maxLines: 2,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. Derive the kinematic equations for constant acceleration...',
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDCD6CA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDCD6CA)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Suggested Presets
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _presets.map((preset) {
                return ActionChip(
                  label: Text(preset, style: const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2DCD0)),
                  onPressed: _isGenerating
                      ? null
                      : () {
                          _promptCtrl.text = preset;
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Progress or Error status
            if (_isGenerating || _generatedVideoPath != null) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: const Color(0xFFE2DCD0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B1C1E)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A4E57),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280))),
                ),
                const SizedBox(width: 12),
                if (_generatedVideoPath != null && widget.onMountToWhiteboard != null) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onMountToWhiteboard!(_generatedVideoPath!, _promptCtrl.text.trim());
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(LucideIcons.layoutGrid, size: 16),
                    label: const Text('Mount to Whiteboard', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _startGeneration,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(LucideIcons.play, size: 16),
                  label: Text(_isGenerating ? 'Rendering...' : 'Generate Video',
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
