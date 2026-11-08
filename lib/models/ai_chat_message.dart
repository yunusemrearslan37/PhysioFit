import 'ai_coach_response.dart';

class AiChatMessage {
  final String? id;
  final String userId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final Map<String, dynamic>? context;
  final DateTime createdAt;

  AiChatMessage({
    this.id,
    required this.userId,
    required this.role,
    required this.content,
    this.context,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

  /// Sunucuda kayıtlı interaktif öneriler (`context.interactive.suggestions`).
  List<String> get followUpSuggestions {
    final interactive = _interactiveBlock;
    if (interactive == null) return const [];
    final raw = interactive['suggestions'];
    if (raw is! List) return const [];
    return raw.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  }

  /// Sunucuda kayıtlı aksiyon butonları (`context.interactive.actions`).
  List<AiCoachAction> get coachActions {
    final interactive = _interactiveBlock;
    if (interactive == null) return const [];
    final raw = interactive['actions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AiCoachAction.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.type.isNotEmpty && a.label.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? get _interactiveBlock {
    final block = context?['interactive'];
    if (block is Map<String, dynamic>) return block;
    if (block is Map) return Map<String, dynamic>.from(block);
    return null;
  }

  /// API yanıtından assistant mesajı oluşturur.
  factory AiChatMessage.fromCoachResponse({
    required String userId,
    required AiCoachResponse response,
  }) {
    return AiChatMessage(
      userId: userId,
      role: 'assistant',
      content: response.reply,
      context: {
        'interactive': {
          'suggestions': response.suggestions,
          'actions': response.actions.map((a) => a.toJson()).toList(),
        },
      },
      createdAt: DateTime.now(),
    );
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      context: json['context'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'role': role,
      'content': content,
      'context': context,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
