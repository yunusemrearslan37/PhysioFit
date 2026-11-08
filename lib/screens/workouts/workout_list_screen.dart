import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../services/auth_service.dart';
import 'my_workout_screen.dart';
import '../../widgets/modern_background.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  final _workoutService = WorkoutService();
  final _authService = AuthService();
  
  List<Workout> _workouts = [];
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
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    // Verileri arka planda yükle, kullanıcıyı bekletme
    try {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        final workouts = await _workoutService.getUserWorkouts(profile.id);
        if (mounted) {
          setState(() {
            _userId = profile.id;
            _workouts = workouts;
            _isLoading = false;
          });
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
            content: Text('Antrenmanlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setActiveWorkout(String workoutId) async {
    if (_userId == null) return;

    try {
      await _workoutService.setActiveWorkout(_userId!, workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktif antrenman güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWorkouts(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aktif antrenman ayarlanırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text(
          'Antrenmanı Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu antrenmanı silmek istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _workoutService.deleteWorkout(workoutId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Antrenman silindi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadWorkouts(); // Listeyi yenile
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Antrenman silinirken hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Antrenmanlarım',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyWorkoutScreen(),
                ),
              ).then((_) => _loadWorkouts()); // Geri dönünce listeyi yenile
            },
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Antrenman',
          ),
        ],
      ),
      body: ModernBackground(
        child: _workouts.isEmpty && !_isLoading
            ? _buildEmptyState()
          : RefreshIndicator(
                  onRefresh: _loadWorkouts,
                  color: _cyanAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      return _buildWorkoutCard(_workouts[index]);
                    },
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MyWorkoutScreen(),
            ),
          ).then((_) => _loadWorkouts()); // Geri dönünce listeyi yenile
        },
        backgroundColor: _cyanAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Yeni Antrenman',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: _textGrey.withOpacity(0.5)),
          const SizedBox(height: 20),
          Text(
            'Henüz antrenman oluşturmadınız',
            style: TextStyle(color: _textGrey, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Yeni antrenman oluşturmak için butona tıklayın',
            style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => _showWorkoutDetails(workout),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            workout.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (workout.isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _cyanAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: _textGrey),
                    color: _cardColor,
                    onSelected: (value) {
                      if (value == 'set_active') {
                        _setActiveWorkout(workout.id);
                      } else if (value == 'delete') {
                        _deleteWorkout(workout.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'set_active',
                        child: Row(
                          children: [
                            Icon(
                              workout.isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: workout.isActive ? _cyanAccent : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              workout.isActive ? 'Aktif' : 'Aktif Yap',
                              style: TextStyle(
                                color: workout.isActive ? _cyanAccent : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.view_list_outlined, size: 16, color: _cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    '${workout.exercises.length} egzersiz',
                    style: TextStyle(color: _textGrey, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: _textGrey),
                  const SizedBox(width: 8),
                  Text(
                    '${workout.weeks} hafta',
                    style: TextStyle(color: _textGrey, fontSize: 14),
                  ),
                ],
              ),
              if (workout.exercises.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: workout.exercises.take(3).map((exercise) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _cyanAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cyanAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${exercise.exerciseName} (${workoutExerciseVolumeText(exercise)})',
                        style: TextStyle(
                          color: _cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (workout.exercises.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${workout.exercises.length - 3} egzersiz daha',
                      style: TextStyle(color: _textGrey.withOpacity(0.7), fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDetails(Workout workout) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: workout.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = workout.exercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (exercise.durationSeconds != null &&
                                exercise.durationSeconds! > 0) ...[
                              _buildDetailChip(
                                workoutExerciseVolumeText(exercise),
                                Icons.timer_outlined,
                              ),
                            ] else ...[
                              _buildDetailChip('${exercise.sets} Set', Icons.repeat),
                              if (exercise.reps != null) ...[
                                const SizedBox(width: 8),
                                _buildDetailChip(
                                    '${exercise.reps} Tekrar', Icons.tag_outlined),
                              ],
                            ],
                            if (exercise.weight != null) ...[
                              const SizedBox(width: 8),
                              _buildDetailChip('${exercise.weight} kg', Icons.scale),
                            ],
                          ],
                        ),
                        if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            exercise.notes!,
                            style: TextStyle(color: _textGrey, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _cyanAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _cyanAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: _cyanAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

