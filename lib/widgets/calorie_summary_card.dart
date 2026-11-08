import 'package:flutter/material.dart';
import '../screens/nutrition/log_calories_screen.dart';
import '../utils/navigation_helper.dart';

class CalorieSummaryCard extends StatelessWidget {
  const CalorieSummaryCard({
    super.key,
    required this.dailyTarget,
    required this.caloriesBurned,
    required this.caloriesConsumed,
    required this.hasProfileData,
    required this.onRefresh,
  });

  final int? dailyTarget;
  final int caloriesBurned;
  final int caloriesConsumed;
  final bool hasProfileData;
  final VoidCallback onRefresh;

  static const Color _cardColor = Color(0x88121A2F);
  static const Color _cyanAccent = Color(0xFF00E5FF);

  int? get _remaining {
    if (dailyTarget == null) return null;
    return dailyTarget! + caloriesBurned - caloriesConsumed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: _cyanAccent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Günlük Kalori',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasProfileData)
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      NavigationHelper.createHomeExitRoute(
                        LogCaloriesScreen(initialCalories: caloriesConsumed),
                      ),
                    );
                    if (result == true) onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      caloriesConsumed > 0 ? 'Düzenle' : 'Giriş yap',
                      style: TextStyle(color: _cyanAccent, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasProfileData)
            Text(
              'Kalori hedefi için profilde boy, kilo ve doğum tarihi girin.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            )
          else ...[
            _row('Hedef', dailyTarget != null ? '$dailyTarget kcal' : '—'),
            const SizedBox(height: 8),
            _row('Yakılan (tahmini)', '$caloriesBurned kcal'),
            const SizedBox(height: 8),
            _row('Alınan', caloriesConsumed > 0 ? '$caloriesConsumed kcal' : 'Girilmedi'),
            if (_remaining != null) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 8),
              _row(
                'Kalan bütçe',
                '${_remaining!} kcal',
                highlight: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? _cyanAccent : Colors.white,
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
