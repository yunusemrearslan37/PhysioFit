import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_goals_service.dart';
import '../../services/user_metrics_service.dart';
import '../../services/user_limitations_service.dart';
import '../../services/personalization_service.dart';
import '../../services/notification_service.dart';
import '../../services/notification_preferences_service.dart';
import '../../services/push_notification_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _authService = AuthService();
  final _goalsService = UserGoalsService();
  final _metricsService = UserMetricsService();
  final _limitationsService = UserLimitationsService();

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Tema renkleri (uygulamayla uyumlu)
  final Color _backgroundColor = const Color(0xFF0B1022);
  final Color _cardColor = const Color(0xFF151B2E);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  // Sayfa 1: Hedef seçimi
  String? _selectedGoal;

  // Sayfa 2: Fiziksel metrikler
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _profileHadBirthDate = false;
  bool _profileHadGender = false;

  // Sayfa 3: Deneyim seviyesi
  String _selectedExperience = 'beginner';

  // Sayfa 4: Haftalık antrenman
  int _workoutDaysPerWeek = 3;

  // Sayfa 5: Hangi günler
  final Set<int> _selectedDays = {};

  // Sayfa 6: Kaç hafta & Program önerisi
  int _programWeeks = 6;
  List<PlanSuggestion> _planSuggestions = [];
  int? _selectedPlanIndex;

  // Sayfa 7: Kısıtlamalar
  final List<Map<String, String>> _selectedLimitations = [];
  String? _selectedLimitationBodyPart;
  String? _selectedLimitationType;

  static const _totalPages = 7;

  static const List<Map<String, dynamic>> _goalOptions = [
    {
      'key': 'weight_loss',
      'title': 'Kilo Verme',
      'subtitle': 'Yağ yakımı ve kardiyoya odaklan',
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'key': 'muscle_gain',
      'title': 'Kas Yapma',
      'subtitle': 'Güç antrenmanı ve hacim kazanımı',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'key': 'physiotherapy',
      'title': 'Fizyoterapi',
      'subtitle': 'Rehabilitasyon ve esneklik',
      'icon': Icons.healing_rounded,
    },
    {
      'key': 'general_fitness',
      'title': 'Genel Fitness',
      'subtitle': 'Dengeli ve sağlıklı yaşam',
      'icon': Icons.favorite_rounded,
    },
  ];

  static const List<Map<String, dynamic>> _experienceOptions = [
    {
      'key': 'beginner',
      'title': 'Başlangıç',
      'subtitle': '0-6 ay deneyim',
      'icon': Icons.emoji_people_rounded,
    },
    {
      'key': 'intermediate',
      'title': 'Orta Seviye',
      'subtitle': '6 ay - 2 yıl deneyim',
      'icon': Icons.directions_run_rounded,
    },
    {
      'key': 'advanced',
      'title': 'İleri Seviye',
      'subtitle': '2+ yıl deneyim',
      'icon': Icons.military_tech_rounded,
    },
  ];

  static const List<String> _bodyParts = [
    'Diz', 'Omuz', 'Bel', 'Boyun', 'Ayak Bileği', 'Dirsek', 'Kalça',
  ];

  static const List<String> _limitationTypes = [
    'Sakatlık', 'Ameliyat', 'Kronik Ağrı', 'Hareket Kısıtlılığı',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (!mounted || profile == null) return;
      setState(() {
        if (profile.birthDate != null) {
          _selectedBirthDate = profile.birthDate;
          _profileHadBirthDate = true;
        }
        if (profile.gender != null && profile.gender!.trim().isNotEmpty) {
          _selectedGender = profile.gender;
          _profileHadGender = true;
        }
      });
    } catch (e) {
      debugPrint('Onboarding profil yükleme hatası: $e');
    }
  }

  bool get _needsBirthDate => !_profileHadBirthDate;
  bool get _needsGender => !_profileHadGender;

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null;
      case 1:
        final heightOk = _heightController.text.isNotEmpty;
        final weightOk = _weightController.text.isNotEmpty;
        final birthOk = !_needsBirthDate || _selectedBirthDate != null;
        final genderOk =
            !_needsGender || (_selectedGender != null && _selectedGender!.isNotEmpty);
        return heightOk && weightOk && birthOk && genderOk;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return _selectedDays.length == _workoutDaysPerWeek;
      case 5:
        return _selectedPlanIndex != null;
      case 6:
        return true;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage == 3) {
      // Gün sayısı değiştiğinde seçili günleri sıfırla (gün sayısına uymazsa)
      if (_selectedDays.length > _workoutDaysPerWeek) {
        _selectedDays.clear();
      }
    }

    if (_currentPage == 4) {
      // Gün seçimi tamam, plan önerileri üret
      _generateSuggestions();
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _generateSuggestions() {
    final service = PersonalizationService();
    setState(() {
      _planSuggestions = service.generatePlanSuggestions(
        goalType: _selectedGoal!,
        daysPerWeek: _workoutDaysPerWeek,
        experienceLevel: _selectedExperience,
        programWeeks: _programWeeks,
      );
      _selectedPlanIndex = null;
    });
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Hedefi kaydet
      await _goalsService.createGoal(
        userId: user.id,
        goalType: _selectedGoal!,
        activityLevel: 'moderate',
        workoutDaysPerWeek: _workoutDaysPerWeek,
        workoutDays: _selectedDays.toList()..sort(),
        programWeeks: _programWeeks,
        experienceLevel: _selectedExperience,
      );

      // 2. Doğum tarihi ve cinsiyet (Google girişi vb. eksik profiller için)
      if (_needsBirthDate || _needsGender) {
        await _authService.updateUserProfile(
          birthDate: _needsBirthDate ? _selectedBirthDate : null,
          gender: _needsGender ? _selectedGender : null,
        );
      }

      // 3. Metrikleri kaydet
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      if (height != null && weight != null) {
        await _metricsService.addMetric(
          userId: user.id,
          height: height,
          weight: weight,
        );
      }

      // 4. Kısıtlamaları kaydet
      for (final limitation in _selectedLimitations) {
        await _limitationsService.addLimitation(
          userId: user.id,
          bodyPart: limitation['bodyPart']!,
          limitationType: limitation['type']!,
        );
      }

      // 5. Seçilen program önerisinden plan üret
      try {
        if (_selectedPlanIndex != null && _planSuggestions.isNotEmpty) {
          await PersonalizationService().generateFromSuggestion(
            userId: user.id,
            suggestion: _planSuggestions[_selectedPlanIndex!],
            goalType: _selectedGoal!,
            experienceLevel: _selectedExperience,
          );
        } else {
          await PersonalizationService().generatePersonalizedPlan(user.id);
        }
      } catch (e) {
        debugPrint('Plan üretme hatası (kritik değil): $e');
      }

      // 6. Antrenman günlerinde bildirim kur
      try {
        final notificationService = NotificationService();
        final granted = await notificationService.requestPermission();
        if (granted && _selectedDays.isNotEmpty) {
          await notificationService.scheduleWorkoutReminders(
            workoutDays: _selectedDays.toList()..sort(),
            hour: 9,
            minute: 0,
          );
          await PushNotificationService().syncTokenForCurrentUser(
            requestPermissionIfNeeded: false,
          );
        }
      } catch (e) {
        debugPrint('Bildirim kurma hatası (kritik değil): $e');
      }

      try {
        await NotificationPreferencesService().applyWaterReminder();
      } catch (e) {
        debugPrint('Su hatırlatıcı kurulum hatası (kritik değil): $e');
      }

      // 7. Onboarding tamamlandı olarak işaretle
      await _authService.markOnboardingCompleted();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),

            // Sayfa içeriği
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildGoalPage(),
                  _buildMetricsPage(),
                  _buildExperiencePage(),
                  _buildWorkoutDaysPage(),
                  _buildWorkoutDaySelectionPage(),
                  _buildProgramSelectionPage(),
                  _buildLimitationsPage(),
                ],
              ),
            ),

            // Alt butonlar
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ─── PROGRESS BAR ───

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adım ${_currentPage + 1} / $_totalPages',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              if (_currentPage == _totalPages - 1)
                Text(
                  'Son adım',
                  style: TextStyle(color: _cyanAccent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              backgroundColor: _cardColor,
              valueColor: AlwaysStoppedAnimation<Color>(_cyanAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SAYFA 1: HEDEF SEÇİMİ ───

  Widget _buildGoalPage() {
    return _buildPageWrapper(
      title: 'Hedefin Ne?',
      subtitle: 'Sana özel bir plan oluşturalım',
      child: Column(
        children: _goalOptions.map((option) {
          final isSelected = _selectedGoal == option['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectionCard(
              icon: option['icon'] as IconData,
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedGoal = option['key'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── SAYFA 2: FİZİKSEL METRİKLER ───

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  Future<void> _selectBirthDate() async {
    var temp = _selectedBirthDate ?? DateTime(2000, 1, 1);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Doğum Tarihi Seç',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: _cyanAccent,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: temp,
                      minimumDate: DateTime(1900),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (value) => temp = value,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedBirthDate = DateTime(temp.year, temp.month, temp.day);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Seç', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Widget item(String value) => ListTile(
              title: Text(value, style: const TextStyle(color: Colors.white)),
              trailing: _selectedGender == value
                  ? Icon(Icons.check, color: _cyanAccent)
                  : null,
              onTap: () => Navigator.of(context).pop(value),
            );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cinsiyet Seç',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              item('Erkek'),
              item('Kadın'),
              item('Diğer'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedGender = selected);
    }
  }

  Widget _buildDemographicPicker({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
    required bool required,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? _cyanAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required && !hasValue ? '$label *' : label,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              hasValue ? Icons.check_circle : Icons.keyboard_arrow_down,
              color: hasValue ? Colors.greenAccent : Colors.white54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsPage() {
    return _buildPageWrapper(
      title: 'Fiziksel Bilgilerin',
      subtitle: _needsBirthDate || _needsGender
          ? 'Kişisel plan ve kalori hedefi için bilgilerini gir'
          : 'Kişisel planın için boy ve kilonu gir',
      child: Column(
        children: [
          if (_needsBirthDate) ...[
            _buildDemographicPicker(
              icon: Icons.cake_outlined,
              label: 'Doğum Tarihi',
              value: _selectedBirthDate != null
                  ? _formatDate(_selectedBirthDate!)
                  : null,
              onTap: _selectBirthDate,
              required: true,
            ),
            const SizedBox(height: 12),
          ],
          if (_needsGender) ...[
            _buildDemographicPicker(
              icon: Icons.people_outline,
              label: 'Cinsiyet',
              value: _selectedGender,
              onTap: _selectGender,
              required: true,
            ),
            const SizedBox(height: 16),
          ],
          _buildInputField(
            controller: _heightController,
            label: 'Boy (cm)',
            icon: Icons.height_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: 'Örn: 175',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _weightController,
            label: 'Kilo (kg)',
            icon: Icons.monitor_weight_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: 'Örn: 70',
          ),
          const SizedBox(height: 24),
          // BMI gösterimi (anlık)
          ValueListenableBuilder(
            valueListenable: _heightController,
            builder: (_, __, ___) {
              return ValueListenableBuilder(
                valueListenable: _weightController,
                builder: (_, __, ___) {
                  final h = double.tryParse(_heightController.text);
                  final w = double.tryParse(_weightController.text);
                  if (h == null || w == null || h <= 0) return const SizedBox.shrink();
                  final bmi = w / ((h / 100) * (h / 100));
                  String category;
                  Color color;
                  if (bmi < 18.5) {
                    category = 'Zayıf';
                    color = Colors.orangeAccent;
                  } else if (bmi < 25) {
                    category = 'Normal';
                    color = Colors.greenAccent;
                  } else if (bmi < 30) {
                    category = 'Fazla Kilolu';
                    color = Colors.orange;
                  } else {
                    category = 'Obez';
                    color = Colors.redAccent;
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, color: color, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'BMI: ${bmi.toStringAsFixed(1)} - $category',
                          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── SAYFA 3: DENEYİM SEVİYESİ ───

  Widget _buildExperiencePage() {
    return _buildPageWrapper(
      title: 'Deneyim Seviyen',
      subtitle: 'Antrenman geçmişine göre seç',
      child: Column(
        children: _experienceOptions.map((option) {
          final isSelected = _selectedExperience == option['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSelectionCard(
              icon: option['icon'] as IconData,
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedExperience = option['key'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── SAYFA 4: HAFTALIK ANTRENMAN GÜNÜ ───

  Widget _buildWorkoutDaysPage() {
    return _buildPageWrapper(
      title: 'Haftada Kaç Gün?',
      subtitle: 'Haftada kaç gün antrenman yapmak istiyorsun?',
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Büyük sayı gösterimi
          Text(
            '$_workoutDaysPerWeek',
            style: TextStyle(
              color: _cyanAccent,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'gün / hafta',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 32),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _cyanAccent,
              inactiveTrackColor: _cardColor,
              thumbColor: _cyanAccent,
              overlayColor: _cyanAccent.withOpacity(0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _workoutDaysPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) {
                setState(() => _workoutDaysPerWeek = value.round());
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 gün', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('7 gün', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          // Tavsiye
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cyanAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cyanAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _cyanAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getWorkoutDaysAdvice(),
                    style: TextStyle(color: Colors.grey[300], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkoutDaysAdvice() {
    if (_workoutDaysPerWeek <= 2) return 'Başlangıç için ideal. Vücudun dinlenmeye ihtiyaç duyar.';
    if (_workoutDaysPerWeek <= 4) return 'Dengeli bir program. Çoğu kişi için en uygun aralık.';
    if (_workoutDaysPerWeek <= 5) return 'Yoğun program. İyi bir dinlenme planı önemli.';
    return 'Çok yoğun! Dinlenme günlerini atlamadığından emin ol.';
  }

  // ─── SAYFA 5: HANGİ GÜNLER ───

  Widget _buildWorkoutDaySelectionPage() {
    const dayNames = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };

    return _buildPageWrapper(
      title: 'Hangi Günler?',
      subtitle: '$_workoutDaysPerWeek gün seçmelisin',
      child: Column(
        children: [
          ...dayNames.entries.map((entry) {
            final dayNum = entry.key;
            final dayName = entry.value;
            final isSelected = _selectedDays.contains(dayNum);
            final canSelect = _selectedDays.length < _workoutDaysPerWeek || isSelected;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(dayNum);
                    } else if (canSelect) {
                      _selectedDays.add(dayNum);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? _cyanAccent.withOpacity(0.12) : _cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _cyanAccent : Colors.white.withOpacity(canSelect ? 0.05 : 0.02),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? _cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            dayName.substring(0, 3),
                            style: TextStyle(
                              color: isSelected ? _cyanAccent : (canSelect ? Colors.white60 : Colors.white24),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (canSelect ? Colors.white70 : Colors.white30),
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: _cyanAccent, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            '${_selectedDays.length} / $_workoutDaysPerWeek gün seçildi',
            style: TextStyle(
              color: _selectedDays.length == _workoutDaysPerWeek ? _cyanAccent : Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SAYFA 6: PROGRAM SÜRESİ & ÖNERİLER ───

  Widget _buildProgramSelectionPage() {
    return _buildPageWrapper(
      title: 'Programını Seç',
      subtitle: 'Sana uygun programlardan birini seç',
      child: Column(
        children: [
          // Hafta sayısı seçimi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Program Süresi', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    Text(
                      '$_programWeeks hafta',
                      style: TextStyle(color: _cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _cyanAccent,
                    inactiveTrackColor: Colors.white.withOpacity(0.05),
                    thumbColor: _cyanAccent,
                    overlayColor: _cyanAccent.withOpacity(0.15),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _programWeeks.toDouble(),
                    min: 2,
                    max: 16,
                    divisions: 14,
                    onChanged: (value) {
                      setState(() {
                        _programWeeks = value.round();
                        _generateSuggestions();
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2 hafta', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    Text('16 hafta', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Önerilen Programlar
          Text(
            'Önerilen Programlar',
            style: TextStyle(color: Colors.grey[300], fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (_planSuggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Yükleniyor...', style: TextStyle(color: Colors.grey[500])),
            )
          else
            ..._planSuggestions.asMap().entries.map((entry) {
              final idx = entry.key;
              final plan = entry.value;
              final isSelected = _selectedPlanIndex == idx;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPlanIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? _cyanAccent.withOpacity(0.1) : _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _cyanAccent : Colors.white.withOpacity(0.05),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected ? _cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            _getPlanIcon(plan.splitType),
                            color: isSelected ? _cyanAccent : Colors.white54,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                plan.description,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniChip('${plan.splitDays.length} gün'),
                                  const SizedBox(width: 6),
                                  _buildMiniChip('${plan.exercisesPerDay} hareket/gün'),
                                  const SizedBox(width: 6),
                                  _buildMiniChip('${plan.weeks} hafta'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: _cyanAccent, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
    );
  }

  IconData _getPlanIcon(String splitType) {
    switch (splitType) {
      case 'full_body':
        return Icons.accessibility_new_rounded;
      case 'upper_lower':
        return Icons.swap_vert_rounded;
      case 'push_pull_legs':
        return Icons.fitness_center_rounded;
      case 'bro_split':
        return Icons.grid_view_rounded;
      case 'cardio_focus':
        return Icons.directions_run_rounded;
      case 'rehab':
        return Icons.healing_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }

  // ─── SAYFA 7: KISITLAMALAR ───

  Widget _buildLimitationsPage() {
    return _buildPageWrapper(
      title: 'Fiziksel Kısıtlaman Var Mı?',
      subtitle: 'Güvenli bir plan için bize bildir (opsiyonel)',
      child: Column(
        children: [
          // Eklenen kısıtlamalar
          ..._selectedLimitations.asMap().entries.map((entry) {
            final i = entry.key;
            final limitation = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${limitation['bodyPart']} - ${limitation['type']}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _selectedLimitations.removeAt(i)),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Bölge seçimi
          _buildDropdown(
            value: _selectedLimitationBodyPart,
            hint: 'Bölge Seç',
            items: _bodyParts,
            onChanged: (v) => setState(() => _selectedLimitationBodyPart = v),
          ),
          const SizedBox(height: 12),

          // Kısıtlama tipi seçimi
          _buildDropdown(
            value: _selectedLimitationType,
            hint: 'Kısıtlama Tipi',
            items: _limitationTypes,
            onChanged: (v) => setState(() => _selectedLimitationType = v),
          ),
          const SizedBox(height: 14),

          // Ekle butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_selectedLimitationBodyPart != null && _selectedLimitationType != null)
                  ? () {
                      setState(() {
                        _selectedLimitations.add({
                          'bodyPart': _selectedLimitationBodyPart!,
                          'type': _selectedLimitationType!,
                        });
                        _selectedLimitationBodyPart = null;
                        _selectedLimitationType = null;
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Kısıtlama Ekle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cyanAccent,
                side: BorderSide(color: _cyanAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledForegroundColor: Colors.grey[700],
              ),
            ),
          ),

          if (_selectedLimitations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'Kısıtlaman yoksa direkt tamamla.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  // ─── ALT BUTONLAR ───

  Widget _buildBottomButtons() {
    final isLastPage = _currentPage == _totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        children: [
          // Geri butonu
          if (_currentPage > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Geri', style: TextStyle(fontSize: 16)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),

          // İleri / Tamamla butonu
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_canProceed && !_isSaving) ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyanAccent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _cardColor,
                disabledForegroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : Text(
                      isLastPage ? 'Tamamla' : 'Devam Et',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ORTAK WIDGET'LAR ───

  Widget _buildPageWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 15),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent.withOpacity(0.1) : _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _cyanAccent : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? _cyanAccent.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? _cyanAccent : Colors.white54, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _cyanAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
          prefixIcon: Icon(icon, color: _cyanAccent, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _cyanAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          dropdownColor: _cardColor,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
