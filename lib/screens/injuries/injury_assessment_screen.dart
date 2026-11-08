import 'package:flutter/material.dart';
import '../../data/injury_assessment_guidance.dart';
import '../../data/physical_therapy_data.dart';
import '../../services/auth_service.dart';
import '../../services/injury_assessment_service.dart';
import '../../services/injury_service.dart';
import '../../services/user_limitations_service.dart';
import '../../models/injury_assessment.dart';
import '../physical_therapy/physical_therapy_exercises_screen.dart';
import '../../widgets/modern_background.dart';
import 'create_rehab_program_screen.dart';
import 'injury_assessment_history_screen.dart';

class InjuryAssessmentScreen extends StatefulWidget {
  const InjuryAssessmentScreen({super.key});

  @override
  State<InjuryAssessmentScreen> createState() => _InjuryAssessmentScreenState();
}

class _InjuryAssessmentScreenState extends State<InjuryAssessmentScreen> {
  static const int _totalSteps = 7;

  final _authService = AuthService();
  final _assessmentService = InjuryAssessmentService();
  final _limitationsService = UserLimitationsService();
  final _injuryService = InjuryService();

  int _currentStep = 0;
  String? _userId;

  final List<String> _selectedRedFlags = [];
  String? _selectedBodyPart;
  String? _selectedPainType;
  String? _painDuration;
  String? _morningStiffness;
  bool? _isUnilateral;
  bool? _improvesWithRest;
  final List<String> _selectedMovements = [];
  String? _rangeOfMotion;
  String? _strength;
  String? _stability;
  final List<String> _selectedRiskFactors = [];

  InjuryAssessmentResult? _assessmentResult;
  String? _savedAssessmentId;
  List<PhysicalTherapyExercise> _recommendedExercises = [];
  bool _isLoading = false;
  bool _showResults = false;
  bool _limitationAdded = false;
  bool _injuryRecordAdded = false;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _dialogColor = const Color(0xFF121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  static const Map<String, List<String>> _bodyPartMovements = {
    'Diz': ['Squat', 'Lunge', 'Koşu', 'Zıplama'],
    'Omuz': ['Ağırlık Kaldırma', 'Overhead Press', 'Pull Up', 'Bench Press'],
    'Bel': ['Deadlift', 'Squat', 'Ağırlık Kaldırma'],
    'Boyun': ['Overhead Press'],
    'Ayak Bileği': ['Koşu', 'Zıplama', 'Lateral Movement'],
    'Dirsek': ['Bicep Curl', 'Tricep Extension', 'Bench Press', 'Pull Up'],
    'Kalça': ['Squat', 'Lunge', 'Deadlift', 'Lateral Movement'],
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) setState(() => _userId = profile?.id);
    } catch (e) {
      debugPrint('Kullanıcı yükleme hatası: $e');
    }
  }

  Future<void> _completeAssessment() async {
    if (_userId == null || _selectedBodyPart == null) return;

    setState(() => _isLoading = true);

    try {
      final functionalityTest = <String, dynamic>{
        'range_of_motion': _rangeOfMotion,
        'strength': _strength,
        'stability': _stability,
        'pain_duration': _painDuration,
        'morning_stiffness': _morningStiffness,
        'is_unilateral': _isUnilateral,
        'improves_with_rest': _improvesWithRest,
        if (_selectedRedFlags.isNotEmpty) 'red_flags': _selectedRedFlags,
      };

      final result = await _assessmentService.assessInjuryRisk(
        bodyPart: _selectedBodyPart!,
        painType: _selectedPainType ?? 'Donuk',
        triggeringMovements: _selectedMovements,
        functionalityTest: functionalityTest,
        riskFactors: _selectedRiskFactors,
        redFlags: _selectedRedFlags,
        painDuration: _painDuration,
        morningStiffness: _morningStiffness,
        isUnilateral: _isUnilateral,
        improvesWithRest: _improvesWithRest,
      );

      final exercises = result.hasRedFlags
          ? <PhysicalTherapyExercise>[]
          : PhysicalTherapyData.getExercisesForBodyPart(_selectedBodyPart!)
              .where((e) => result.recommendedExerciseIds.contains(e.name))
              .toList();

      final assessment = InjuryAssessment(
        userId: _userId!,
        bodyPart: _selectedBodyPart!,
        painType: _selectedPainType ?? 'Belirtilmedi',
        triggeringMovements: _selectedMovements,
        functionalityTest: functionalityTest,
        riskFactors: _selectedRiskFactors,
        severityScore: result.severityScore,
        recommendedInjuryType: result.recommendedInjuryType,
        recommendedExerciseIds: result.recommendedExerciseIds,
        createdAt: DateTime.now(),
      );

      final saved = await _assessmentService.saveAssessment(assessment);

      if (!mounted) return;
      setState(() {
        _assessmentResult = result;
        _savedAssessmentId = saved.id;
        _recommendedExercises = exercises;
        _showResults = true;
        _isLoading = false;
        _limitationAdded = false;
        _injuryRecordAdded = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analiz hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addLimitationToProfile() async {
    if (_userId == null || _assessmentResult == null || _selectedBodyPart == null) return;

    try {
      await _limitationsService.addLimitation(
        userId: _userId!,
        bodyPart: _selectedBodyPart!,
        limitationType: 'sakatlık',
        severity: InjuryAssessmentGuidance.severityToLimitationLevel(
          _assessmentResult!.riskLevel,
        ),
        notes: _assessmentResult!.recommendedInjuryType,
      );
      if (!mounted) return;
      setState(() => _limitationAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kısıtlama profilinize eklendi. Antrenman önerileri buna göre filtrelenecek.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kısıtlama eklenemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addInjuryRecord() async {
    if (_userId == null || _assessmentResult == null || _selectedBodyPart == null) return;

    try {
      await _injuryService.addInjury(
        userId: _userId!,
        injuryType: _assessmentResult!.recommendedInjuryType ?? 'Sakatlık analizi',
        bodyPart: _selectedBodyPart,
        severity: InjuryAssessmentGuidance.severityToInjuryLevel(
          _assessmentResult!.riskLevel,
        ),
        date: DateTime.now(),
        notes: 'Analiz puanı: ${_assessmentResult!.severityScore}/100',
      );
      if (!mounted) return;
      setState(() => _injuryRecordAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sakatlık kaydı oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt oluşturulamadı: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return _selectedBodyPart != null;
      case 2:
        return _selectedPainType != null;
      case 3:
        return _painDuration != null &&
            _morningStiffness != null &&
            _isUnilateral != null &&
            _improvesWithRest != null;
      case 4:
        return _selectedMovements.isNotEmpty;
      case 5:
        return _rangeOfMotion != null && _strength != null && _stability != null;
      case 6:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _completeAssessment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _resetAssessment() {
    setState(() {
      _currentStep = 0;
      _showResults = false;
      _selectedRedFlags.clear();
      _selectedBodyPart = null;
      _selectedPainType = null;
      _painDuration = null;
      _morningStiffness = null;
      _isUnilateral = null;
      _improvesWithRest = null;
      _selectedMovements.clear();
      _rangeOfMotion = null;
      _strength = null;
      _stability = null;
      _selectedRiskFactors.clear();
      _assessmentResult = null;
      _savedAssessmentId = null;
      _recommendedExercises.clear();
      _limitationAdded = false;
      _injuryRecordAdded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Sakatlık Analizi'),
        backgroundColor: _cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Geçmiş analizler',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InjuryAssessmentHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ModernBackground(
        child: _showResults
            ? _buildResultsView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressIndicator(),
                    const SizedBox(height: 30),
                    _buildStepContent(),
                    const SizedBox(height: 30),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: index <= _currentStep ? _cyanAccent : Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildRedFlagStep();
      case 1:
        return _buildBodyPartSelection();
      case 2:
        return _buildPainTypeSelection();
      case 3:
        return _buildPainContextStep();
      case 4:
        return _buildTriggeringMovements();
      case 5:
        return _buildFunctionalityTest();
      case 6:
        return _buildRiskFactors();
      default:
        return const SizedBox();
    }
  }

  Widget _buildRedFlagStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acil Belirti Kontrolü',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Aşağıdakilerden herhangi biri varsa işaretleyin',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        if (_selectedRedFlags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acil belirti işaretlendi. Analiz sonunda doktora yönlendirme gösterilecek.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        ...injuryRedFlags.map((flag) {
          final id = flag['id']!;
          final isSelected = _selectedRedFlags.contains(id);
          return _buildSelectionCard(
            title: flag['title']!,
            subtitle: flag['description'],
            isSelected: isSelected,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedRedFlags.remove(id);
                } else {
                  _selectedRedFlags.add(id);
                }
              });
            },
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Hiçbiri yoksa boş bırakıp devam edin',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBodyPartSelection() {
    const bodyParts = ['Diz', 'Omuz', 'Bel', 'Boyun', 'Ayak Bileği', 'Dirsek', 'Kalça'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hangi bölgede sorun yaşıyorsunuz?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...bodyParts.map((part) => _buildSelectionCard(
              title: part,
              isSelected: _selectedBodyPart == part,
              onTap: () {
                final allowed = _bodyPartMovements[part] ?? const <String>[];
                setState(() {
                  _selectedBodyPart = part;
                  _selectedMovements.removeWhere((m) => !allowed.contains(m));
                });
              },
            )),
      ],
    );
  }

  Widget _buildPainTypeSelection() {
    const painTypes = [
      {'name': 'Keskin', 'description': 'Ani ve keskin ağrı'},
      {'name': 'Yanma', 'description': 'Yanma hissi veren ağrı'},
      {'name': 'Batma', 'description': 'Batan, delici ağrı'},
      {'name': 'Donuk', 'description': 'Donuk, sürekli ağrı'},
      {'name': 'Zonklama', 'description': 'Zonklayan, nabız gibi ağrı'},
      {'name': 'Gerginlik', 'description': 'Gerginlik ve sıkışma hissi'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ağrı tipiniz nasıl?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...painTypes.map((type) => _buildSelectionCard(
              title: type['name']!,
              subtitle: type['description'],
              isSelected: _selectedPainType == type['name'],
              onTap: () => setState(() => _selectedPainType = type['name']),
            )),
      ],
    );
  }

  Widget _buildPainContextStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ağrı bağlamı',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildTestQuestion('Ağrı ne zamandır var?', _painDuration, const [
          '0-3 gün (akut)',
          '3-7 gün',
          '1-4 hafta',
          '1 aydan uzun (kronik)',
        ], (v) => setState(() => _painDuration = v)),
        const SizedBox(height: 16),
        _buildTestQuestion('Sabah tutukluğu ne kadar sürüyor?', _morningStiffness, const [
          'Yok veya 15 dk altı',
          '15-30 dk',
          '30-60 dk',
          '1 saatten uzun',
        ], (v) => setState(() => _morningStiffness = v)),
        const SizedBox(height: 16),
        _buildYesNoQuestion('Ağrı tek taraflı mı?', _isUnilateral, (v) => setState(() => _isUnilateral = v)),
        const SizedBox(height: 16),
        _buildYesNoQuestion('Dinlenince ağrı azalıyor mu?', _improvesWithRest, (v) => setState(() => _improvesWithRest = v)),
      ],
    );
  }

  Widget _buildYesNoQuestion(String title, bool? value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSelectionCard(title: 'Evet', isSelected: value == true, onTap: () => onChanged(true))),
            const SizedBox(width: 12),
            Expanded(child: _buildSelectionCard(title: 'Hayır', isSelected: value == false, onTap: () => onChanged(false))),
          ],
        ),
      ],
    );
  }

  Widget _buildTriggeringMovements() {
    final movements = _bodyPartMovements[_selectedBodyPart] ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hangi hareketler ağrıyı tetikliyor?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: movements.map((movement) {
            final isSelected = _selectedMovements.contains(movement);
            return FilterChip(
              label: Text(movement),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMovements.add(movement);
                  } else {
                    _selectedMovements.remove(movement);
                  }
                });
              },
              selectedColor: _cyanAccent.withValues(alpha: 0.3),
              checkmarkColor: _cyanAccent,
              labelStyle: TextStyle(
                color: isSelected ? _cyanAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: _cardColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFunctionalityTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fonksiyonellik Testi',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildTestQuestion('Hareket Açıklığı', _rangeOfMotion, const [
          'Normal', 'Hafif Kısıtlı', 'Kısıtlı', 'Çok Kısıtlı',
        ], (v) => setState(() => _rangeOfMotion = v)),
        const SizedBox(height: 16),
        _buildTestQuestion('Güç', _strength, const [
          'Normal', 'Orta', 'Zayıf', 'Çok Zayıf',
        ], (v) => setState(() => _strength = v)),
        const SizedBox(height: 16),
        _buildTestQuestion('Stabilite', _stability, const [
          'Stabil', 'Hafif Dengesiz', 'Dengesiz', 'Çok Dengesiz',
        ], (v) => setState(() => _stability = v)),
      ],
    );
  }

  Widget _buildRiskFactors() {
    const riskFactors = [
      'Geçmiş Sakatlık', 'Aşırı Antrenman', 'Yaş (40+)',
      'Sedanter Yaşam', 'Düşük Esneklik', 'Düşük Kas Gücü', 'Düşük Denge',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk Faktörleri',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Opsiyonel', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: riskFactors.map((factor) {
            final isSelected = _selectedRiskFactors.contains(factor);
            return FilterChip(
              label: Text(factor),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRiskFactors.add(factor);
                  } else {
                    _selectedRiskFactors.remove(factor);
                  }
                });
              },
              selectedColor: _cyanAccent.withValues(alpha: 0.3),
              checkmarkColor: _cyanAccent,
              backgroundColor: _cardColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTestQuestion(
    String title,
    String? selectedValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...options.map((option) => _buildSelectionCard(
              title: option,
              isSelected: selectedValue == option,
              onTap: () => onChanged(option),
            )),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent.withValues(alpha: 0.2) : _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _cyanAccent : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? _cyanAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: _cyanAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[700]!),
              ),
              child: const Text('Geri', style: TextStyle(color: Colors.white70)),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _canProceedToNextStep() && !_isLoading ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[800],
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _currentStep == _totalSteps - 1 ? 'Analizi Tamamla' : 'İleri',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final result = _assessmentResult;
    if (result == null) return const SizedBox();

    final guidance = result.guidance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.hasRedFlags) _buildEmergencyBanner(),
          _buildResultSummaryCard(result),
          const SizedBox(height: 20),
          _buildGuidanceSection('Tahmini İyileşme', guidance.recoveryEstimate, _cyanAccent),
          const SizedBox(height: 16),
          _buildListSection('Yapılabilecekler', guidance.recommendedDos, Colors.green),
          const SizedBox(height: 16),
          _buildListSection('Kaçınılacaklar', guidance.recommendedDonts, Colors.red),
          const SizedBox(height: 16),
          _buildGuidanceSection('Uzman Önerisi', guidance.doctorAdvice, Colors.orange),
          if (_recommendedExercises.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Önerilen Egzersizler',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._recommendedExercises.map(_buildExerciseCard),
          ],
          const SizedBox(height: 24),
          if (!result.hasRedFlags) ...[
            _buildActionButton(
              label: _limitationAdded ? 'Kısıtlama Eklendi' : 'Profilime Kısıtlama Ekle',
              icon: Icons.person_outline,
              onPressed: _limitationAdded ? null : _addLimitationToProfile,
              color: Colors.teal,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: _injuryRecordAdded ? 'Kayıt Oluşturuldu' : 'Sakatlık Kaydı Oluştur',
              icon: Icons.medical_information_outlined,
              onPressed: _injuryRecordAdded ? null : _addInjuryRecord,
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),
            if (!result.hasRedFlags && _savedAssessmentId != null && _selectedBodyPart != null)
              _buildActionButton(
                label: 'Rehabilitasyon Programı Oluştur',
                icon: Icons.playlist_add,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateRehabProgramScreen(
                        bodyPart: _selectedBodyPart!,
                        assessmentId: _savedAssessmentId,
                        suggestedExerciseNames: result.recommendedExerciseIds,
                      ),
                    ),
                  );
                },
                color: _cyanAccent,
              ),
          ],
          const SizedBox(height: 24),
          _buildDisclaimer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Yeni Analiz Yap', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Acil Değerlendirme Gerekli',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'İşaretlediğiniz belirtiler ciddi olabilir. Egzersiz önerisi yerine doktora başvurmanız önerilir.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummaryCard(InjuryAssessmentResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _dialogColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analiz Sonucu',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildResultItem('Risk Seviyesi', result.riskLevel, _getRiskColor(result.severityScore)),
          const SizedBox(height: 12),
          _buildResultItem('Şiddet Puanı', '${result.severityScore}/100', _getRiskColor(result.severityScore)),
          if (result.recommendedInjuryType != null) ...[
            const SizedBox(height: 12),
            _buildResultItem('Değerlendirme', result.recommendedInjuryType!, Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidanceSection(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dialogColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dialogColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: onPressed == null ? Colors.grey : color),
        label: Text(label, style: TextStyle(color: onPressed == null ? Colors.grey : Colors.white)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: onPressed == null ? Colors.grey : color),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu analiz tıbbi teşhis değildir. Ciddi ağrı veya sakatlık durumunda mutlaka bir sağlık uzmanına danışın.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14))),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  Widget _buildExerciseCard(PhysicalTherapyExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(exercise.description, style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 2),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhysicalTherapyExercisesScreen(initialBodyPart: _selectedBodyPart),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}
