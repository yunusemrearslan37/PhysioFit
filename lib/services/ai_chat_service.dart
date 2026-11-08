import '../config/supabase_config.dart';
import '../models/ai_chat_message.dart';

class AiChatService {
  final _supabase = SupabaseConfig.client;

  Future<List<AiChatMessage>> getChatHistory(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('ai_chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => AiChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Sohbet geçmişi getirme hatası: $e');
    }
  }

  Future<AiChatMessage> saveMessage({
    required String userId,
    required String role,
    required String content,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _supabase
          .from('ai_chat_messages')
          .insert({
            'user_id': userId,
            'role': role,
            'content': content,
            'context': context,
          })
          .select()
          .single();

      return AiChatMessage.fromJson(response);
    } catch (e) {
      throw Exception('Mesaj kaydetme hatası: $e');
    }
  }

  Future<void> clearChatHistory(String userId) async {
    try {
      await _supabase
          .from('ai_chat_messages')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Sohbet geçmişi silme hatası: $e');
    }
  }

  Future<List<AiChatMessage>> getRecentMessages(String userId, {int count = 10}) async {
    try {
      final response = await _supabase
          .from('ai_chat_messages')
          .select()
          .eq('user_id', userId)
          .neq('role', 'system')
          .order('created_at', ascending: false)
          .limit(count);

      final messages = (response as List)
          .map((json) => AiChatMessage.fromJson(json))
          .toList();

      return messages.reversed.toList();
    } catch (e) {
      throw Exception('Son mesajları getirme hatası: $e');
    }
  }
}
