import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  @override
  String get providerName => 'Gemini (${AiConfig.geminiModel})';

  @override
  bool get isAvailable => AiConfig.isGeminiConfigured;

  @override
  Future<String> chat(List<Map<String, String>> messages) async {
    if (!isAvailable) {
      throw Exception('Gemini API anahtarı ayarlanmamış. Ayarlar > AI Koç bölümünden girin.');
    }

    // Gemini API formatına dönüştür
    final systemInstruction = _extractSystemPrompt(messages);
    final contents = _convertToGeminiFormat(messages);

    final url = '${AiConfig.geminiBaseUrl}/models/${AiConfig.geminiModel}:generateContent?key=${AiConfig.geminiApiKey}';

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.95,
      },
    };

    if (systemInstruction.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [{'text': systemInstruction}],
      };
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null || (text as String).isEmpty) {
          throw Exception('Gemini boş yanıt döndürdü.');
        }
        return text;
      } else if (response.statusCode == 429) {
        throw Exception('İstek limiti aşıldı. Biraz bekleyip tekrar deneyin.');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorMsg = data['error']?['message'] ?? 'Bilinmeyen hata';
        debugPrint('Gemini 400 hatası: $errorMsg');
        throw Exception('İstek hatası: $errorMsg');
      } else if (response.statusCode == 403) {
        throw Exception('API anahtarı geçersiz veya bu model için yetkiniz yok.');
      } else {
        debugPrint('Gemini hata: ${response.statusCode} - ${response.body}');
        throw Exception('AI servisi yanıt veremedi (${response.statusCode}).');
      }
    } on http.ClientException catch (e) {
      throw Exception('Bağlantı hatası: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  String _extractSystemPrompt(List<Map<String, String>> messages) {
    final systemMessages = messages.where((m) => m['role'] == 'system');
    if (systemMessages.isEmpty) return '';
    return systemMessages.map((m) => m['content']).join('\n');
  }

  List<Map<String, dynamic>> _convertToGeminiFormat(List<Map<String, String>> messages) {
    final contents = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg['role'] == 'system') continue;

      final role = msg['role'] == 'assistant' ? 'model' : 'user';
      contents.add({
        'role': role,
        'parts': [{'text': msg['content'] ?? ''}],
      });
    }

    // Gemini ilk mesajın user olmasını bekler
    if (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.insert(0, {
        'role': 'user',
        'parts': [{'text': 'Merhaba'}],
      });
    }

    return contents;
  }
}
