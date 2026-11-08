import '../models/ai_chat_message.dart';
import '../models/ai_coach_response.dart';
import '../config/supabase_config.dart';
import 'ai_chat_service.dart';
import 'auth_service.dart';

class AiCoachService {
  final _supabase = SupabaseConfig.client;
  final _chatService = AiChatService();
  final _authService = AuthService();

  AiCoachService();

  bool get isAvailable => true;
  String get providerName => 'Supabase Edge Function (Gemini)';

  /// Kullanıcı mesajı gönder, yapılandırılmış AI yanıtı al.
  Future<AiChatMessage> sendMessage(String userMessage) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Giriş yapmalısınız.');

    try {
      final response = await _supabase.functions.invoke(
        'ai-coach-chat',
        body: {'message': userMessage},
      );

      final data = response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('AI servisinden geçersiz yanıt alındı.');
      }

      if (data['error'] != null && (data['reply'] == null || '${data['reply']}'.trim().isEmpty)) {
        throw Exception(data['error']?.toString() ?? 'AI yanıt üretmedi.');
      }

      final coachResponse = AiCoachResponse.fromApi(data);
      if (coachResponse.reply.isEmpty) {
        throw Exception(data['error']?.toString() ?? 'AI yanıt üretmedi.');
      }

      return AiChatMessage.fromCoachResponse(
        userId: user.id,
        response: coachResponse,
      );
    } catch (e) {
      throw Exception('AI yanıt hatası: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  /// Sohbet geçmişini getir
  Future<List<AiChatMessage>> getChatHistory() async {
    final user = _authService.currentUser;
    if (user == null) return [];
    return _chatService.getChatHistory(user.id);
  }

  /// Sohbet geçmişini temizle
  Future<void> clearHistory() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _chatService.clearChatHistory(user.id);
  }
}
