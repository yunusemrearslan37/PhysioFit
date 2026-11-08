/// Günlük kalori özeti (AI koç ve ana sayfa için).
class CalorieDailySummary {
  final int? dailyTarget;
  final int burnedToday;
  final int consumedToday;
  final bool hasProfileData;

  const CalorieDailySummary({
    required this.dailyTarget,
    required this.burnedToday,
    required this.consumedToday,
    required this.hasProfileData,
  });

  int? get remainingBudget {
    if (dailyTarget == null) return null;
    return dailyTarget! + burnedToday - consumedToday;
  }

  bool get isAvailable => hasProfileData && dailyTarget != null;
}
