import 'package:flutter/material.dart';
import '../../data/physical_therapy_data.dart';
import '../../widgets/modern_background.dart';

class PhysicalTherapyExercisesScreen extends StatefulWidget {
  final String? initialBodyPart;

  const PhysicalTherapyExercisesScreen({super.key, this.initialBodyPart});

  @override
  State<PhysicalTherapyExercisesScreen> createState() => _PhysicalTherapyExercisesScreenState();
}

class _PhysicalTherapyExercisesScreenState extends State<PhysicalTherapyExercisesScreen> {
  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _textGrey = const Color(0xFFB0B3B8);

  // Kategoriler ve egzersizler
  late List<PhysicalTherapyCategory> _categories;
  final Set<String> _expandedCategories = <String>{};
  final Set<String> _expandedExercises = <String>{};

  @override
  void initState() {
    super.initState();
    _categories = PhysicalTherapyData.getCategories();
    final initialCategory =
        widget.initialBodyPart == null
            ? null
            : PhysicalTherapyData.getCategoryForBodyPart(widget.initialBodyPart!);
    if (initialCategory != null) {
      _expandedCategories.add(initialCategory.englishName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCategory =
        widget.initialBodyPart == null
            ? null
            : PhysicalTherapyData.getCategoryForBodyPart(widget.initialBodyPart!);
    final List<PhysicalTherapyCategory> visibleCategories =
        initialCategory == null ? _categories : [initialCategory];

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Fizyoterapi Egzersizleri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ModernBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(20.0),
        itemCount: visibleCategories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(visibleCategories[index]);
        },
      ),
      ),
    );
  }

  void _toggleCategory(String key) {
    setState(() {
      if (_expandedCategories.contains(key)) {
        _expandedCategories.remove(key);
      } else {
        _expandedCategories.add(key);
      }
    });
  }

  void _toggleExercise(String key) {
    setState(() {
      if (_expandedExercises.contains(key)) {
        _expandedExercises.remove(key);
      } else {
        _expandedExercises.add(key);
      }
    });
  }

  Widget _buildCategoryCard(PhysicalTherapyCategory category) {
    final isExpanded = _expandedCategories.contains(category.englishName);
    final imageAsset = _getCategoryImageAsset(category.englishName);
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleCategory(category.englishName),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _cyanAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageAsset == null
                            ? Icon(
                                _getCategoryIcon(category.englishName),
                                color: _cyanAccent,
                                size: 24,
                              )
                            : Image.asset(
                                imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Görsel bulunamazsa ikon fallback
                                  return Icon(
                                    _getCategoryIcon(category.englishName),
                                    color: _cyanAccent,
                                    size: 24,
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.exerciseCount} Egzersiz • ${category.level}',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? _cyanAccent : _textGrey,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Smooth expand/collapse
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? RepaintBoundary(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: List.generate(
                              category.exercises.length,
                              (i) => _buildExerciseItem(category.exercises[i]),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(PhysicalTherapyExercise exercise) {
    final isExpanded = _expandedExercises.contains(exercise.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleExercise(exercise.name),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _cyanAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.description,
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isExpanded
                              ? 'Yapılışı gizle'
                              : 'Yapılışı göster (${exercise.instructions.length} adım)',
                          style: TextStyle(
                            color: _cyanAccent.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? _cyanAccent : _textGrey,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: Colors.white.withOpacity(0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.play_lesson_outlined,
                                color: _cyanAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Yapılış rehberi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...exercise.instructions.asMap().entries.map(
                                (entry) => _buildInstructionStep(
                                  stepIndex: entry.key + 1,
                                  text: entry.value,
                                ),
                              ),
                          const SizedBox(height: 8),
                          _buildSafetyTip(),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required int stepIndex,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _cyanAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$stepIndex',
                style: TextStyle(
                  color: _cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _textGrey,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined,
              color: Colors.orange.shade300, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hafif gerilme normal olabilir; keskin veya artan ağrıda hareketi durdurun.',
              style: TextStyle(
                color: Colors.orange.shade100,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String englishName) {
    switch (englishName.toLowerCase()) {
      case 'neck':
        return Icons.face;
      case 'shoulder':
        return Icons.accessibility_new;
      case 'knee':
        return Icons.directions_walk;
      case 'lower back':
        return Icons.healing;
      case 'hip':
        return Icons.fitness_center;
      case 'ankle':
        return Icons.directions_run;
      default:
        return Icons.medical_services;
    }
  }

  /// Kategori görsellerini assets'ten çekmek için eşleme.
  /// Sen `assets/images/physical_therapy/` altına görselleri ekleyince burada yolları güncellemen yeterli.
  /// Görsel yoksa otomatik olarak ikon fallback çalışır.
  String? _getCategoryImageAsset(String englishName) {
    switch (englishName.toLowerCase()) {
      case 'neck':
        return 'assets/images/neck.png';
      case 'shoulder':
        return 'assets/images/shoulder.png';
      case 'knee':
        return 'assets/images/diz.jpg';
      case 'lower back':
        return 'assets/images/bel.jpg';
      case 'hip':
        return 'assets/images/kalça.jpg';
      case 'ankle':
        return 'assets/images/ayak.jpg';
      default:
        return null;
    }
  }
}

