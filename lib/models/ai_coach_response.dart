/// AI koç yanıtındaki uygulama içi aksiyon.
class AiCoachAction {
  final String type;
  final String label;
  final String? exerciseId;
  final String? workoutId;
  final String? message;

  const AiCoachAction({
    required this.type,
    required this.label,
    this.exerciseId,
    this.workoutId,
    this.message,
  });

  factory AiCoachAction.fromJson(Map<String, dynamic> json) {
    return AiCoachAction(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? json['exercise_id'] as String?,
      workoutId: json['workoutId'] as String? ?? json['workout_id'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'label': label,
        if (exerciseId != null) 'exerciseId': exerciseId,
        if (workoutId != null) 'workoutId': workoutId,
        if (message != null) 'message': message,
      };
}

/// Edge Function'dan dönen yapılandırılmış koç yanıtı.
class AiCoachResponse {
  final String reply;
  final List<String> suggestions;
  final List<AiCoachAction> actions;

  const AiCoachResponse({
    required this.reply,
    this.suggestions = const [],
    this.actions = const [],
  });

  factory AiCoachResponse.fromApi(Map<String, dynamic> data) {
    final suggestionsRaw = data['suggestions'];
    final actionsRaw = data['actions'];

    return AiCoachResponse(
      reply: (data['reply'] as String?)?.trim() ?? '',
      suggestions: suggestionsRaw is List
          ? suggestionsRaw
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .take(3)
              .toList()
          : const [],
      actions: actionsRaw is List
          ? actionsRaw
              .whereType<Map>()
              .map((e) => AiCoachAction.fromJson(Map<String, dynamic>.from(e)))
              .where((a) => a.type.isNotEmpty && a.label.isNotEmpty)
              .take(2)
              .toList()
          : const [],
    );
  }
}
