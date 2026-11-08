import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../services/workout_progress_service.dart';
import '../../services/auth_service.dart';
import '../../services/calorie_tracking_service.dart';
import '../../widgets/modern_background.dart';

class DailyWorkoutTrackerScreen extends StatefulWidget {
  const DailyWorkoutTrackerScreen({super.key, this.initialWorkoutId});

  /// Push bildiriminden açılırsa yüklenecek program (aktif olmasa da).
  final String? initialWorkoutId;

  @override
  State<DailyWorkoutTrackerScreen> createState() => _DailyWorkoutTrackerScreenState();
}

class _DailyWorkoutTrackerScreenState extends State<DailyWorkoutTrackerScreen> {
  final _workoutService = WorkoutService();
  final _progressService = WorkoutProgressService();
  final _authService = AuthService();
  final _calorieTracking = CalorieTrackingService();

  Workout? _activeWorkout;
  Map<String, bool> _weeklyProgress = {};
  bool _isLoading = true;
  String? _userId;

  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _textGrey = const Color(0xFFB0B3B8);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Verileri arka planda yükle, kullanıcıyı bekletme
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        _userId = profile.id;

        Workout? workout;
        final deepLinkId = widget.initialWorkoutId?.trim();
        if (deepLinkId != null && deepLinkId.isNotEmpty) {
          final byId = await _workoutService.getWorkoutById(deepLinkId);
          if (byId != null && byId.userId == profile.id) {
            workout = byId;
          }
        }
        workout ??= await _workoutService.getActiveWorkout(profile.id);

        if (workout != null) {
          final weeklyProgress = await _progressService.getWeeklyProgress(
            userId: profile.id,
            workoutId: workout.id,
          );

          if (mounted) {
            setState(() {
              _activeWorkout = workout;
              _weeklyProgress = weeklyProgress;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDay(DateTime date) async {
    if (_activeWorkout == null || _userId == null) return;

    final dateString = date.toIso8601String().split('T')[0];
    final currentStatus = _weeklyProgress[dateString] ?? false;
    final newStatus = !currentStatus;

    try {
      await _progressService.markWorkoutDay(
        userId: _userId!,
        workoutId: _activeWorkout!.id,
        date: date,
        completed: newStatus,
      );

      if (newStatus) {
        await _calorieTracking.onWorkoutCompleted(
          userId: _userId!,
          workout: _activeWorkout!,
          date: date,
        );
      } else {
        await _calorieTracking.onWorkoutUncompleted(
          userId: _userId!,
          workout: _activeWorkout!,
          date: date,
        );
      }

      setState(() {
        _weeklyProgress[dateString] = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Antrenman tamamlandı! Yakılan kalori tahmini güncellendi.'
                  : 'Antrenman iptal edildi',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _getDayName(DateTime date) {
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Günlük Takip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ModernBackground(
        child: _isLoading
            ? const SizedBox.shrink() // Veriler yüklenirken boş ekran
          : _activeWorkout == null
              ? _buildNoActiveWorkout()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Aktif Antrenman Bilgisi
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cyanAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.fitness_center, color: _cyanAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _activeWorkout!.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_activeWorkout!.weeks} haftalık program • ${_activeWorkout!.exercises.length} egzersiz',
                              style: TextStyle(color: _textGrey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Haftalık Takip
                      const Text(
                        'Bu Hafta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Günler
                      Row(
                        children: _getWeekDays().map((date) {
                          final dateString = date.toIso8601String().split('T')[0];
                          final isCompleted = _weeklyProgress[dateString] ?? false;
                          final isToday = dateString == DateTime.now().toIso8601String().split('T')[0];

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleDay(date),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? _cyanAccent
                                      : isToday
                                          ? _cardColor
                                          : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isToday
                                        ? _cyanAccent
                                        : Colors.white.withOpacity(0.1),
                                    width: isToday ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _getDayName(date),
                                      style: TextStyle(
                                        color: isCompleted
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        color: isCompleted
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 20,
                                      color: isCompleted
                                          ? Colors.black
                                          : _textGrey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // İstatistikler
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Tamamlanan',
                              '${_weeklyProgress.values.where((v) => v).length}',
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Kalan',
                              '${7 - _weeklyProgress.values.where((v) => v).length}',
                              Icons.schedule,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildNoActiveWorkout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: _textGrey.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'Aktif antrenman bulunamadı',
            style: TextStyle(color: _textGrey, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Antrenmanlarınızdan birini aktif yapın',
            style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _cyanAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: _textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

