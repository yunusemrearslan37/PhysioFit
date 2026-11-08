import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import 'ai_provider.dart';

class OpenRouterProvider implements AiProvider {
  final String model;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 3);

  OpenRouterProvider({this.model = AiConfig.openRouterModel});

  @override
  String get providerName => 'OpenRouter ($model)';

  @override
  bool get isAvailable => AiConfig.isOpenRouterConfigured;

  @override
  Future<String> chat(List<Map<String, String>> messages) async {
    if (!isAvailable) {
      throw Exception('API anahtarı ayarlanmamış. Ayarlar > AI Koç bölümünden API anahtarınızı girin.');
    }

    final fallbacks = [
      'google/gemma-4-31b-it:free',
      'google/gemma-4-26b-a4b-it:free',
      'openrouter/free',
    ];
    final modelsToTry = [model, ...fallbacks.where((m) => m != model)];

    for (final currentModel in modelsToTry) {
      try {
        final result = await _tryChat(messages, currentModel);
        return result;
      } on _RateLimitException {
        debugPrint('Rate limit: $currentModel, sonraki model deneniyor...');
        continue;
      }
    }

    throw Exception('Tüm modeller meşgul. Lütfen 1-2 dakika bekleyip tekrar deneyin.');
  }

  Future<String> _tryChat(List<Map<String, String>> messages, String targetModel) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        debugPrint('Yeniden deneme $attempt/$_maxRetries ($targetModel)...');
        await Future.delayed(_retryDelay * attempt);
      }

      try {
        final response = await http.post(
          Uri.parse('${AiConfig.openRouterBaseUrl}/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AiConfig.openRouterApiKey}',
            'HTTP-Referer': 'com.example.bitirme_proje',
            'X-Title': 'PhysioFit',
          },
          body: jsonEncode({
            'model': targetModel,
            'messages': messages,
            'max_tokens': 1024,
            'temperature': 0.7,
          }),
        );

        debugPrint('OpenRouter [$targetModel] status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Bazı modeller error döndürebilir 200 içinde
          if (data['error'] != null) {
            debugPrint('OpenRouter API error in body: ${data['error']}');
            if (attempt == _maxRetries) throw _RateLimitException();
            continue;
          }

          final content = data['choices']?[0]?['message']?['content'];
          if (content == null || (content as String).isEmpty) {
            throw Exception('AI boş yanıt döndürdü.');
          }
          return content;
        } else if (response.statusCode == 429) {
          if (attempt == _maxRetries) throw _RateLimitException();
          continue;
        } else if (response.statusCode == 401) {
          throw Exception('API anahtarı geçersiz. Ayarlar > AI Koç bölümünden kontrol edin.');
        } else {
          debugPrint('OpenRouter hata [$targetModel]: ${response.statusCode} - ${response.body}');
          // 400/404: model yok veya format hatası -> retry yapmadan sonraki modele geç
          if (response.statusCode == 400 || response.statusCode == 404) {
            throw _RateLimitException();
          }
          if (attempt == _maxRetries) {
            throw Exception('AI servisi yanıt veremedi (${response.statusCode}).');
          }
        }
      } on http.ClientException catch (e) {
        if (attempt == _maxRetries) throw Exception('Bağlantı hatası: $e');
      } on _RateLimitException {
        rethrow;
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Beklenmeyen hata: $e');
      }
    }

    throw _RateLimitException();
  }
}

class _RateLimitException implements Exception {}
