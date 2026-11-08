import '../config/supabase_config.dart';

class PushNotificationApiService {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String body,
    required String notificationType,
    Map<String, dynamic> data = const {},
  }) async {
    final response = await _supabase.functions.invoke(
      'send-push',
      body: {
        'title': title,
        'body': body,
        'notificationType': notificationType,
        'data': data,
      },
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Push servisinden geçersiz yanıt alındı.');
    }

    if (payload['error'] != null) {
      throw Exception(payload['error'].toString());
    }

    return payload;
  }

  Future<Map<String, dynamic>> sendSelfTestNotification({
    required String title,
    required String body,
    String notificationType = 'general',
    Map<String, dynamic> data = const {},
  }) {
    return sendNotification(
      title: title,
      body: body,
      notificationType: notificationType,
      data: data,
    );
  }
}
