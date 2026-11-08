import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import 'exercise_detail_screen.dart';

class ExerciseCategoryScreen extends StatefulWidget {
  final String categoryKey;
  final String difficultyKey;
  final String difficultyName;

  const ExerciseCategoryScreen({
    super.key,
    required this.categoryKey,
    required this.difficultyKey,
    required this.difficultyName,
  });

  @override
  State<ExerciseCategoryScreen> createState() => _ExerciseCategoryScreenState();
}

class _ExerciseCategoryScreenState extends State<ExerciseCategoryScreen> {
  final _exerciseService = ExerciseService();
  
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  String _getCategoryName(String key) {
    final categoryMap = {
      'Chest': 'Göğüs',
      'Back': 'Sırt',
      'Legs': 'Bacak',
      'Arms': 'Kol',
      'Shoulders': 'Omuz',
      'Core': 'Karın',
      'Cardio': 'Kardiyovasküler',
    };
    return categoryMap[key] ?? key;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Önce kategoriye göre filtrele
      List<Exercise> exercises = await _exerciseService.getExercisesByCategory(widget.categoryKey);
      
      // Sonra zorluk seviyesine göre filtrele
      exercises = exercises.where((exercise) {
        return exercise.difficulty == widget.difficultyKey;
      }).toList();

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Egzersizler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getCategoryName(widget.categoryKey)} - ${widget.difficultyName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu kategoride egzersiz bulunamadı',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yakında eklenecek',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Başlık ve bilgi
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: _getDifficultyColor(widget.difficultyKey).withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(widget.difficultyKey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_exercises.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getCategoryName(widget.categoryKey)} Egzersizleri',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${widget.difficultyName} seviye program',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Egzersiz listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExerciseDetailScreen(exerciseId: exercise.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // İkon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getDifficultyColor(widget.difficultyKey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: _getDifficultyColor(widget.difficultyKey),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exercise.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (exercise.muscleGroups != null && exercise.muscleGroups!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: exercise.muscleGroups!.take(3).map((muscle) {
                          return Chip(
                            label: Text(
                              muscle,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Ok ikonu
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

