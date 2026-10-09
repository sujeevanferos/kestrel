import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/ai_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _ai = AIService.instance;

  late AIProvider _provider;
  late TextEditingController _geminiKeyCtrl;
  late TextEditingController _grokKeyCtrl;
  late String _geminiModel;
  late String _grokModel;

  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _provider = _ai.currentProvider;
    _geminiKeyCtrl = TextEditingController(text: _ai.geminiApiKey);
    _grokKeyCtrl = TextEditingController(text: _ai.grokApiKey);
    _geminiModel = _ai.geminiModel;
    _grokModel = _ai.grokModel;
  }

  @override
  void dispose() {
    _geminiKeyCtrl.dispose();
    _grokKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
    });

    final key = _provider == AIProvider.gemini ? _geminiKeyCtrl.text : _grokKeyCtrl.text;
    final success = await _ai.verifyConnection(_provider, key);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success
            ? 'Connection verified successfully.'
            : 'Authentication failed. Please verify your API key.';
      });
    }
  }

  Future<void> _save() async {
    await _ai.saveSettings(
      provider: _provider,
      geminiKey: _geminiKeyCtrl.text,
      grokKey: _grokKeyCtrl.text,
      geminiModel: _geminiModel,
      grokModel: _grokModel,
    );
    if (mounted) Navigator.of(context).pop();
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
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.settings, size: 22, color: Color(0xFF2D3139)),
                const SizedBox(width: 12),
                const Text(
                  'Workspace Settings',
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
            const Divider(color: Color(0xFFE2DCD0), height: 32),

            // AI Provider Selector
            const Text(
              'Active AI Service Provider',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4E57),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCD6CA)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AIProvider>(
                  value: _provider,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: AIProvider.gemini,
                      child: Text('Google Gemini (Vision & Tutoring)',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                    ),
                    DropdownMenuItem(
                      value: AIProvider.grok,
                      child: Text('xAI Grok (Language & Reasoning)',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                    ),
                  ],
                  onChanged: (p) {
                    if (p != null) setState(() => _provider = p);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // API Key Input
            Text(
              _provider == AIProvider.gemini ? 'Google Gemini API Key' : 'xAI Grok API Key',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4E57),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _provider == AIProvider.gemini ? _geminiKeyCtrl : _grokKeyCtrl,
              obscureText: true,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: _provider == AIProvider.gemini ? 'AIzaSy...' : 'xai-...',
                prefixIcon: const Icon(LucideIcons.key, size: 16, color: Color(0xFF6B7280)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(height: 16),

            // Connection Test Feedback
            if (_testMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess! ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess! ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess! ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                      size: 16,
                      color: _testSuccess! ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _testSuccess! ? const Color(0xFF065F46) : const Color(0xFF991B1B),
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
                OutlinedButton.icon(
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Verify Connection',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D3139),
                    side: const BorderSide(color: Color(0xFFDCD6CA)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isTesting ? null : _testConnection,
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1C1E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Settings',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
