import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../../services/exercise_service.dart';
import '../../services/workout_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/modern_background.dart';

class MyWorkoutScreen extends StatefulWidget {
  const MyWorkoutScreen({super.key});

  @override
  State<MyWorkoutScreen> createState() => _MyWorkoutScreenState();
}

class _MyWorkoutScreenState extends State<MyWorkoutScreen> {
  final _exerciseService = ExerciseService();
  final _workoutService = WorkoutService();
  final _authService = AuthService();
  
  final _workoutNameController = TextEditingController();
  
  List<Exercise> _allExercises = [];
  List<WorkoutExercise> _selectedExercises = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;
  String? _selectedCategory; // Seçili kategori
  int _selectedWeeks = 4; // Varsayılan 4 hafta
  
  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _sheetColor = const Color(0xFF121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _textGrey = const Color(0xFFB0B3B8);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getUserProfile();
      final exercises = await _exerciseService.getAllExercises();
      
      setState(() {
        _userId = profile?.id;
        _allExercises = exercises;
        _isLoading = false;
      });
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

  void _addExercise(Exercise exercise) {
    setState(() {
      final isCardio = (exercise.category ?? '').trim().toLowerCase() == 'cardio';
      if (isCardio) {
        _selectedExercises.add(WorkoutExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: 1,
          reps: null,
          durationSeconds: 180,
          restSeconds: null,
        ));
      } else {
        _selectedExercises.add(WorkoutExercise(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          sets: 3,
          reps: 10,
        ));
      }
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _updateExercise(int index, WorkoutExercise updated) {
    setState(() {
      _selectedExercises[index] = updated;
    });
  }

  Exercise? _exerciseMeta(String exerciseId) {
    for (final e in _allExercises) {
      if (e.id == exerciseId) return e;
    }
    return null;
  }

  /// Kayıtta süre varsa veya veritabanındaki egzersiz kardiyosu — süre satırı gösterilir.
  bool _isCardioLine(WorkoutExercise w) {
    if (w.durationSeconds != null) return true;
    final meta = _exerciseMeta(w.exerciseId);
    return meta != null &&
        (meta.category ?? '').trim().toLowerCase() == 'cardio';
  }

  Future<void> _saveWorkout() async {
    if (_workoutNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen program adı girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir egzersiz ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _workoutService.createWorkout(
        userId: _userId!,
        name: _workoutNameController.text.trim(),
        exercises: _selectedExercises,
        weeks: _selectedWeeks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Program kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Antrenmanım',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ModernBackground(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _cyanAccent))
          : Column(
              children: [
                // Program Adı
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _workoutNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Program Adı',
                      labelStyle: TextStyle(color: _textGrey),
                      hintText: 'Örn: Göğüs Antrenmanı',
                      hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.edit_outlined, color: _cyanAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cyanAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: _cardColor,
                    ),
                  ),
                ),

                // Hafta Seçimi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: _cyanAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Program Süresi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kaç hafta boyunca yapılacak?',
                          style: TextStyle(color: _textGrey, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [2, 4, 6, 8, 12].map((weeks) {
                            final isSelected = _selectedWeeks == weeks;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedWeeks = weeks),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _cyanAccent
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? _cyanAccent
                                            : Colors.white.withOpacity(0.2),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$weeks hafta',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Seçilen Egzersizler
                if (_selectedExercises.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seçilen Egzersizler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedExercises.length} egzersiz',
                          style: TextStyle(color: _textGrey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      itemCount: _selectedExercises.length,
                      itemBuilder: (context, index) {
                        final workoutExercise = _selectedExercises[index];
                        return _buildExerciseCard(workoutExercise, index);
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add_outlined,
                              size: 64, color: _textGrey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz egzersiz eklenmedi',
                            style: TextStyle(color: _textGrey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aşağıdan egzersiz seçin',
                            style: TextStyle(
                                color: _textGrey.withOpacity(0.7), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Egzersiz Seçme Butonu ve Kaydet Butonu
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showExerciseSelector(),
                          icon: const Icon(Icons.add),
                          label: const Text('Egzersiz Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Programı Kaydet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  workoutExercise.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isCardioLine(workoutExercise))
            _buildNumberField(
              label: 'Süre (saniye)',
              value: workoutExercise.durationSeconds ?? 180,
              onChanged: (value) {
                if (value != null && value > 0) {
                  _updateExercise(
                    index,
                    WorkoutExercise(
                      exerciseId: workoutExercise.exerciseId,
                      exerciseName: workoutExercise.exerciseName,
                      sets: 1,
                      reps: null,
                      durationSeconds: value,
                      weight: workoutExercise.weight,
                      restSeconds: workoutExercise.restSeconds,
                      notes: workoutExercise.notes,
                    ),
                  );
                }
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    label: 'Set',
                    value: workoutExercise.sets,
                    onChanged: (value) {
                      if (value != null && value > 0) {
                        _updateExercise(
                          index,
                          WorkoutExercise(
                            exerciseId: workoutExercise.exerciseId,
                            exerciseName: workoutExercise.exerciseName,
                            sets: value,
                            reps: workoutExercise.reps,
                            durationSeconds: workoutExercise.durationSeconds,
                            weight: workoutExercise.weight,
                            restSeconds: workoutExercise.restSeconds,
                            notes: workoutExercise.notes,
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    label: 'Tekrar',
                    value: workoutExercise.reps,
                    onChanged: (value) {
                      _updateExercise(
                        index,
                        WorkoutExercise(
                          exerciseId: workoutExercise.exerciseId,
                          exerciseName: workoutExercise.exerciseName,
                          sets: workoutExercise.sets,
                          reps: value,
                          durationSeconds: workoutExercise.durationSeconds,
                          weight: workoutExercise.weight,
                          restSeconds: workoutExercise.restSeconds,
                          notes: workoutExercise.notes,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: _textGrey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: value?.toString() ?? '0',
              hintStyle: TextStyle(color: _textGrey),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (text) {
              final intValue = int.tryParse(text);
              onChanged(intValue);
            },
          ),
        ),
      ],
    );
  }

  // Kategori isimlerini Türkçe'ye çevir
  String _getCategoryName(String? category) {
    if (category == null) return 'Diğer';
    final categoryMap = {
      'Chest': 'Göğüs',
      'Back': 'Sırt',
      'Shoulders': 'Omuz',
      'Arms': 'Kol',
      'Legs': 'Bacak',
      'Core': 'Karın',
      'Cardio': 'Kardiyovasküler',
    };
    return categoryMap[category] ?? category;
  }

  // Kategorilere göre egzersizleri grupla
  Map<String, List<Exercise>> _groupExercisesByCategory() {
    final grouped = <String, List<Exercise>>{};
    for (var exercise in _allExercises) {
      final category = exercise.category ?? 'Diğer';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(exercise);
    }
    return grouped;
  }

  void _showExerciseSelector() {
    final groupedExercises = _groupExercisesByCategory();
    final categories = groupedExercises.keys.toList()..sort();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _sheetColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              color: _sheetColor,
              child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Egzersiz Seç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Kategori Filtreleri (Chips)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Tümü butonu
                      _buildCategoryChip(
                        'Tümü',
                        _selectedCategory == null,
                        () {
                          setModalState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Kategori butonları
                      ...categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            _getCategoryName(category),
                            isSelected,
                            () {
                              setModalState(() {
                                _selectedCategory = isSelected ? null : category;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Egzersiz Listesi
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selectedCategory == null
                        ? categories.length
                        : 1,
                    itemBuilder: (context, index) {
                      if (_selectedCategory == null) {
                        // Tüm kategorileri göster
                        final category = categories[index];
                        final exercises = groupedExercises[category]!;
                        return _buildCategorySection(
                          _getCategoryName(category),
                          exercises,
                          context,
                        );
                      } else {
                        // Sadece seçili kategoriyi göster
                        final exercises = groupedExercises[_selectedCategory]!;
                        return _buildCategorySection(
                          _getCategoryName(_selectedCategory),
                          exercises,
                          context,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _cyanAccent : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String categoryName,
    List<Exercise> exercises,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            categoryName,
            style: TextStyle(
              color: _cyanAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...exercises.map((exercise) {
          final isSelected = _selectedExercises
              .any((e) => e.exerciseId == exercise.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _cyanAccent : Colors.white.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                exercise.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              subtitle: exercise.description != null
                  ? Text(
                      exercise.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    )
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: _cyanAccent, size: 28)
                  : Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
              onTap: () {
                if (!isSelected) {
                  _addExercise(exercise);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${exercise.name} eklendi'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

