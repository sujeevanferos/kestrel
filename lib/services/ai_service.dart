import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AIProvider {
  gemini,
  grok,
}

class AIService {
  static final AIService instance = AIService._internal();
  AIService._internal();

  static const String _keyProvider = 'ai_provider';
  static const String _keyGeminiKey = 'gemini_api_key';
  static const String _keyGrokKey = 'grok_api_key';
  static const String _keyGeminiModel = 'gemini_model';
  static const String _keyGrokModel = 'grok_model';

  AIProvider _provider = AIProvider.gemini;
  String _geminiApiKey = '';
  String _grokApiKey = '';
  String _geminiModel = 'gemini-2.0-flash';
  String _grokModel = 'grok-2-latest';

  AIProvider get currentProvider => _provider;
  String get geminiApiKey => _geminiApiKey;
  String get grokApiKey => _grokApiKey;
  String get geminiModel => _geminiModel;
  String get grokModel => _grokModel;

  bool get hasValidKey {
    if (_provider == AIProvider.gemini) return _geminiApiKey.trim().isNotEmpty;
    if (_provider == AIProvider.grok) return _grokApiKey.trim().isNotEmpty;
    return false;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final providerStr = prefs.getString(_keyProvider) ?? 'gemini';
    _provider = providerStr == 'grok' ? AIProvider.grok : AIProvider.gemini;
    _geminiApiKey = prefs.getString(_keyGeminiKey) ?? '';
    _grokApiKey = prefs.getString(_keyGrokKey) ?? '';
    _geminiModel = prefs.getString(_keyGeminiModel) ?? 'gemini-2.0-flash';
    _grokModel = prefs.getString(_keyGrokModel) ?? 'grok-2-latest';
  }

  Future<void> saveSettings({
    required AIProvider provider,
    required String geminiKey,
    required String grokKey,
    required String geminiModel,
    required String grokModel,
  }) async {
    _provider = provider;
    _geminiApiKey = geminiKey.trim();
    _grokApiKey = grokKey.trim();
    _geminiModel = geminiModel.trim();
    _grokModel = grokModel.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvider, provider == AIProvider.grok ? 'grok' : 'gemini');
    await prefs.setString(_keyGeminiKey, _geminiApiKey);
    await prefs.setString(_keyGrokKey, _grokApiKey);
    await prefs.setString(_keyGeminiModel, _geminiModel);
    await prefs.setString(_keyGrokModel, _grokModel);
  }

  /// Verifies API connectivity with user's configured key
  Future<bool> verifyConnection(AIProvider provider, String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      if (provider == AIProvider.gemini) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [{'text': 'Test'}]
              }
            ]
          }),
        );
        return res.statusCode == 200;
      } else {
        // xAI Grok (OpenAI-compatible)
        final url = Uri.parse('https://api.x.ai/v1/chat/completions');
        final res = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _grokModel,
            'messages': [
              {'role': 'user', 'content': 'Test'}
            ],
            'max_tokens': 5,
          }),
        );
        return res.statusCode == 200;
      }
    } catch (_) {
      return false;
    }
  }

  /// Sends a structured prompt to generate pedagogical lesson LaTeX
  Future<String> generateLessonLatex(String prompt) async {
    if (!hasValidKey) {
      throw Exception('Please configure an API key for ${_provider.name.toUpperCase()} in Settings.');
    }

    const systemPrompt = '''You are an expert STEM educator. Generate a clean, structured LaTeX presentation lesson for the topic requested.
Output ONLY the LaTeX code inside a document environment, using standard article or beamer styling.''';

    if (_provider == AIProvider.gemini) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
      );
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': systemPrompt}]
          },
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      );
      if (res.statusCode != 200) {
        throw Exception('Gemini API Error: ${res.statusCode} - ${res.body}');
      }
      final data = jsonDecode(res.body);
      return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
    } else {
      final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_grokApiKey',
        },
        body: jsonEncode({
          'model': _grokModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
        }),
      );
      if (res.statusCode != 200) {
        throw Exception('Grok API Error: ${res.statusCode} - ${res.body}');
      }
      final data = jsonDecode(res.body);
      return data['choices'][0]['message']['content'] ?? '';
    }
  }
}
