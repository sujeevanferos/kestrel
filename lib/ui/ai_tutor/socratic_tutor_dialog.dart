import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/ai_service.dart';

class SocraticTutorDialog extends StatefulWidget {
  final void Function(String text)? onInsertToBoard;

  const SocraticTutorDialog({super.key, this.onInsertToBoard});

  @override
  State<SocraticTutorDialog> createState() => _SocraticTutorDialogState();
}

class _SocraticTutorDialogState extends State<SocraticTutorDialog> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const List<String> _quickPrompts = [
    'How do I begin finding the eigenvalues of a matrix?',
    'Why does angular momentum remain conserved in orbital mechanics?',
    'What is the physical meaning of divergence and curl?',
    'Give me a hint on solving Bernoulli differential equations.',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? presetText]) async {
    final query = presetText ?? _inputCtrl.text.trim();
    if (query.isEmpty) return;

    if (!AIService.instance.hasValidKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your Gemini or Grok API key in Settings.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }

    _inputCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final historyForApi = _messages.sublist(0, _messages.length - 1);
      final response = await AIService.instance.askSocraticTutor(
        question: query,
        history: historyForApi,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Error consulting tutor: ${e.toString().replaceAll('Exception: ', '')}',
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 640,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Socratic AI STEM Tutor',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1C1E),
                      ),
                    ),
                    Text(
                      'Guided discovery without spoiling answers',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 24),

            // Messages area
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.lightbulb, size: 36, color: const Color(0xFFD97706).withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          const Text(
                            'Ask for guidance on any mathematical or physics concept.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _quickPrompts.map((q) {
                              return ActionChip(
                                label: Text(q, style: const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE2DCD0)),
                                onPressed: () => _sendMessage(q),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: _messages.length,
                      itemBuilder: (context, idx) {
                        final msg = _messages[idx];
                        final isUser = msg['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 500),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF1B1C1E) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUser ? Colors.transparent : const Color(0xFFE2DCD0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    msg['content'] ?? '',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  if (!isUser && widget.onInsertToBoard != null) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          widget.onInsertToBoard!(msg['content'] ?? '');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Hint added to whiteboard as Sticky Note'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(LucideIcons.stickyNote, size: 12),
                                        label: const Text('Add to Board', style: TextStyle(fontSize: 11)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF2563EB),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text(
                      'Tutor is formulating a guiding hint...',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Type your question or current thought process...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2DCD0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2DCD0)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  icon: const Icon(LucideIcons.send, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
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
