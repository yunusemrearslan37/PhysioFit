class AiConfig {
  // Gemini
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.5-flash';

  // OpenRouter (yedek)
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterModel = 'google/gemma-4-31b-it:free';

  // Aktif provider
  static String _activeProvider = 'gemini'; // 'gemini' veya 'openrouter'
  static String get activeProvider => _activeProvider;
  static set activeProvider(String value) => _activeProvider = value;

  // Gemini API key
  static String? _geminiApiKey;
  static String? get geminiApiKey => _geminiApiKey;
  static void setGeminiApiKey(String key) => _geminiApiKey = key;
  static bool get isGeminiConfigured => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;

  // OpenRouter API key
  static String? _openRouterApiKey;
  static String? get openRouterApiKey => _openRouterApiKey;
  static void setOpenRouterApiKey(String key) => _openRouterApiKey = key;
  static bool get isOpenRouterConfigured => _openRouterApiKey != null && _openRouterApiKey!.isNotEmpty;

  // Genel kullanılabilirlik
  static bool get isConfigured {
    if (_activeProvider == 'gemini') return isGeminiConfigured;
    return isOpenRouterConfigured;
  }

  // Eski uyumluluk (OpenRouter key)
  static String? get apiKey => _openRouterApiKey;
  static void setApiKey(String key) => setOpenRouterApiKey(key);
}
