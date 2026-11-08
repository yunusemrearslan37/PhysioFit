/// Provider-agnostic AI arayüzü
/// İleride farklı bir model/sağlayıcıya geçmek için sadece yeni bir
/// implementasyon yazıp AiCoachService'te değiştirmek yeterli.
abstract class AiProvider {
  /// Sohbet mesajları listesi göndererek yanıt al
  /// [messages] format: [{'role': 'system'|'user'|'assistant', 'content': '...'}]
  Future<String> chat(List<Map<String, String>> messages);

  /// Provider'ın kullanılabilir olup olmadığını kontrol et
  bool get isAvailable;

  /// Provider adı
  String get providerName;
}
