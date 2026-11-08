import 'package:flutter/material.dart';
import '../../data/physical_therapy_data.dart';
import '../../models/rehab_plan.dart';
import '../../services/auth_service.dart';
import '../../services/rehab_plan_service.dart';
import '../../widgets/modern_background.dart';
import 'rehab_plan_tracker_screen.dart';

class CreateRehabProgramScreen extends StatefulWidget {
  const CreateRehabProgramScreen({
    super.key,
    required this.bodyPart,
    this.assessmentId,
    this.suggestedExerciseNames = const [],
  });

  final String bodyPart;
  final String? assessmentId;
  final List<String> suggestedExerciseNames;

  @override
  State<CreateRehabProgramScreen> createState() => _CreateRehabProgramScreenState();
}

class _CreateRehabProgramScreenState extends State<CreateRehabProgramScreen> {
  final _nameController = TextEditingController();
  final _rehabService = RehabPlanService();
  final _authService = AuthService();

  final List<RehabPlanExercise> _selectedExercises = [];
  List<PhysicalTherapyExercise> _availableExercises = [];
  bool _isSaving = false;
  int _totalDays = 7;

  static const Color _cardColor = Color(0x88121A2F);
  static const Color _dialogColor = Color(0xFF121A2F);
  static const Color _cyanAccent = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _nameController.text = '${widget.bodyPart} Rehabilitasyon Programı';
    _availableExercises = PhysicalTherapyData.getExercisesForBodyPart(widget.bodyPart);
    if (_availableExercises.isEmpty) {
      _availableExercises = PhysicalTherapyData.getCategories()
          .expand((c) => c.exercises)
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _isSelected(PhysicalTherapyExercise exercise) {
    return _selectedExercises.any((e) => e.exerciseName == exercise.name);
  }

  void _toggleExercise(PhysicalTherapyExercise exercise) {
    setState(() {
      if (_isSelected(exercise)) {
        _selectedExercises.removeWhere((e) => e.exerciseName == exercise.name);
      } else {
        _selectedExercises.add(RehabPlanExercise(
          exerciseName: exercise.name,
          description: exercise.description,
          sets: 2,
          reps: 10,
        ));
      }
    });
  }

  void _updateExercise(int index, RehabPlanExercise updated) {
    setState(() => _selectedExercises[index] = updated);
  }

  Future<void> _saveProgram() async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program adı girin'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doktorunuzun önerdiği en az bir hareket seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final plan = await _rehabService.createPlan(
        userId: user.id,
        bodyPart: widget.bodyPart,
        name: _nameController.text.trim(),
        exercises: _selectedExercises,
        totalDays: _totalDays,
        assessmentId: widget.assessmentId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RehabPlanTrackerScreen(planId: plan.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggested = widget.suggestedExerciseNames.toSet();

    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        title: const Text('Rehab Programı Oluştur'),
        backgroundColor: _cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ModernBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _dialogColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${widget.bodyPart} bölgesi için doktorunuzun önerdiği rehabilitasyon hareketlerini seçerek kendi programınızı oluşturun.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Program Adı',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: _cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Plan süresi: $_totalDays gün', style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: _totalDays.toDouble(),
                    min: 3,
                    max: 30,
                    divisions: 27,
                    activeColor: _cyanAccent,
                    label: '$_totalDays gün',
                    onChanged: (v) => setState(() => _totalDays = v.round()),
                  ),
                  if (_selectedExercises.isNotEmpty) ...[
                    const Text(
                      'Seçilen Hareketler',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_selectedExercises.length, (i) {
                      final ex = _selectedExercises[i];
                      return _buildSelectedExerciseCard(i, ex);
                    }),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Rehabilitasyon Hareketleri',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._availableExercises.map((exercise) {
                    final isSuggested = suggested.contains(exercise.name);
                    final selected = _isSelected(exercise);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _cyanAccent.withValues(alpha: 0.12)
                            : _cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSuggested
                              ? Colors.orange.withValues(alpha: 0.6)
                              : selected
                                  ? _cyanAccent
                                  : Colors.grey[800]!,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _toggleExercise(exercise),
                        title: Text(
                          exercise.name,
                          style: TextStyle(
                            color: selected ? _cyanAccent : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          exercise.description,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSuggested)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.recommend, color: Colors.orange, size: 18),
                              ),
                            Icon(
                              selected ? Icons.check_circle : Icons.add_circle_outline,
                              color: selected ? _cyanAccent : Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProgram,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Programı Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedExerciseCard(int index, RehabPlanExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dialogColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _stepper(
                label: 'Set',
                value: exercise.sets,
                onChanged: (v) => _updateExercise(index, exercise.copyWith(sets: v)),
              ),
              const SizedBox(width: 16),
              _stepper(
                label: 'Tekrar',
                value: exercise.reps ?? 10,
                onChanged: (v) => _updateExercise(index, exercise.copyWith(reps: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
        ),
        Text('$value', style: const TextStyle(color: Colors.white)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: Icon(Icons.add_circle_outline, color: _cyanAccent, size: 20),
        ),
      ],
    );
  }
}
