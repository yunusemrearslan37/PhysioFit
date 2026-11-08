import 'package:flutter/material.dart';
import '../../widgets/modern_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/workout_service.dart';
import '../../services/workout_progress_service.dart';
import '../../services/user_goals_service.dart';
import '../../services/user_metrics_service.dart';
import '../../services/daily_nutrition_service.dart';
import '../../services/calorie_calculator_service.dart';
import '../../services/calorie_tracking_service.dart';
import '../../models/user_profile.dart';
import '../../models/workout.dart';
import '../../models/user_goal.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/push_navigation.dart';
import '../exercises/exercise_list_screen.dart';
import '../workouts/workout_list_screen.dart';
import '../workouts/daily_workout_tracker_screen.dart';
import '../../services/rehab_plan_service.dart';
import '../../models/rehab_plan.dart';
import '../injuries/rehab_plan_tracker_screen.dart';
import '../injuries/injury_assessment_screen.dart';
import '../physical_therapy/physical_therapy_exercises_screen.dart';
import '../strength/strength_tracking_screen.dart';
import '../timer/timer_stopwatch_screen.dart';
import '../profile/profile_screen.dart';
import '../equipment_recognition/equipment_recognition_screen.dart';
import '../../services/ai_coach_context_service.dart';
import '../chat/ai_chat_screen.dart';
import '../../widgets/calorie_summary_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _workoutService = WorkoutService();
  final _progressService = WorkoutProgressService();
  final _goalsService = UserGoalsService();
  final _metricsService = UserMetricsService();
  final _nutritionService = DailyNutritionService();
  final _calorieTracking = CalorieTrackingService();
  final _rehabPlanService = RehabPlanService();
  String? _userName;
  UserProfile? _userProfile;
  double _weeklyProgress = 0.0;
  Workout? _activeWorkout;
  int _workoutDay = 0;
  UserGoal? _activeGoal;
  int? _dailyCalorieTarget;
  int _caloriesBurnedToday = 0;
  int _caloriesConsumedToday = 0;
  bool _hasCalorieProfileData = false;
  RehabPlan? _activeRehabPlan;
  double _rehabProgress = 0.0;
  int _rehabCompletedDays = 0;
  bool _isTodayExercisesExpanded = false;

  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PushNavigation.flushPendingWorkoutNavigation();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          if (profile != null) {
            // Önce name'i kontrol et, yoksa email'in @ öncesini al
            if (profile.name != null && profile.name!.isNotEmpty) {
              _userName = profile.name;
            } else {
              // E-posta adresinden kullanıcı adını çıkar (@ öncesi)
              final emailParts = profile.email.split('@');
              _userName = emailParts.isNotEmpty ? emailParts[0] : 'Kullanıcı';
            }
          } else {
            // Profil bulunamadıysa, auth kullanıcısından bilgi al
            final user = _authService.currentUser;
            if (user != null && user.email != null) {
              // E-posta adresinden kullanıcı adını çıkar (@ öncesi)
              final emailParts = user.email!.split('@');
              _userName = emailParts.isNotEmpty ? emailParts[0] : 'Kullanıcı';
            } else {
              _userName = 'Misafir';
            }
          }
        });
      }

      // Haftalık ilerleme + hedef + metrikleri yükle
      if (profile != null) {
        await Future.wait([
          _loadWeeklyProgress(profile.id),
          _loadGoalAndMetrics(profile.id),
          _loadCalorieSummary(profile.id, profile),
          _loadRehabPlan(profile.id),
        ]);
      }
    } catch (e) {
      debugPrint('Kullanıcı profili yüklenirken hata: $e');
      // Hata durumunda auth kullanıcısından bilgi al
      final user = _authService.currentUser;
      if (mounted) {
        setState(() {
          if (user != null && user.email != null) {
            // E-posta adresinden kullanıcı adını çıkar (@ öncesi)
            final emailParts = user.email!.split('@');
            _userName = emailParts.isNotEmpty ? emailParts[0] : 'Kullanıcı';
          } else {
            _userName = 'Misafir';
          }
        });
      }
    }
  }

  Future<void> _loadRehabPlan(String userId) async {
    try {
      final plan = await _rehabPlanService.getActivePlan(userId);
      if (plan == null) {
        if (mounted) {
          setState(() {
            _activeRehabPlan = null;
            _rehabProgress = 0;
            _rehabCompletedDays = 0;
          });
        }
        return;
      }

      final ratio = await _rehabPlanService.getPlanCompletionRatio(
        userId: userId,
        rehabPlanId: plan.id,
        totalDays: plan.totalDays,
      );
      final completed = await _rehabPlanService.getCompletedDays(
        userId: userId,
        rehabPlanId: plan.id,
      );

      if (mounted) {
        setState(() {
          _activeRehabPlan = plan;
          _rehabProgress = ratio;
          _rehabCompletedDays = completed.length;
        });
      }
    } catch (e) {
      debugPrint('Rehab planı yükleme hatası: $e');
    }
  }

  Future<void> _loadGoalAndMetrics(String userId) async {
    try {
      final goal = await _goalsService.getActiveGoal(userId);
      if (mounted) {
        setState(() {
          _activeGoal = goal;
        });
      }
    } catch (e) {
      debugPrint('Hedef/metrik yükleme hatası: $e');
    }
  }

  Future<void> _loadCalorieSummary(String userId, UserProfile profile) async {
    try {
      final metric = await _metricsService.getLatestMetric(userId);
      final goal = _activeGoal ?? await _goalsService.getActiveGoal(userId);
      final nutrition = await _nutritionService.getForDate(
        userId: userId,
        date: DateTime.now(),
      );
      final burned = await _calorieTracking.analyticsService.getCaloriesBurnedForDate(
        userId: userId,
        date: DateTime.now(),
      );

      int? target;
      var hasData = false;
      if (metric?.weight != null &&
          metric?.height != null &&
          profile.age != null &&
          metric!.weight! > 0 &&
          metric.height! > 0) {
        hasData = true;
        target = CalorieCalculatorService.calculateDailyTarget(
          weightKg: metric.weight!,
          heightCm: metric.height!,
          age: profile.age!,
          gender: profile.gender,
          activityLevel: goal?.activityLevel ?? 'moderate',
          goalType: goal?.goalType ?? 'general_fitness',
        );
      }

      if (mounted) {
        setState(() {
          _dailyCalorieTarget = target;
          _caloriesBurnedToday = burned;
          _caloriesConsumedToday = nutrition?.caloriesConsumed ?? 0;
          _hasCalorieProfileData = hasData;
        });
      }
    } catch (e) {
      debugPrint('Kalori özeti yükleme hatası: $e');
    }
  }

  Future<void> _loadWeeklyProgress(String userId) async {
    try {
      final activeWorkout = await _workoutService.getActiveWorkout(userId);
      if (activeWorkout != null) {
        // Programın tüm süresi için tamamlama yüzdesini hesapla
        // Tüm haftalar dolduğunda %100'e ulaşır
        final progress =
            await _progressService.getWorkoutProgramCompletionPercentage(
          userId: userId,
          workoutId: activeWorkout.id,
          totalWeeks: activeWorkout.weeks,
        );

        // Antrenman gününü hesapla
        final workoutDay = await _calculateWorkoutDay(userId, activeWorkout.id);

        if (mounted) {
          setState(() {
            _weeklyProgress = progress;
            _activeWorkout = activeWorkout;
            _workoutDay = workoutDay;
          });
        }
      } else {
        // Aktif antrenman yoksa ilerleme 0
        if (mounted) {
          setState(() {
            _weeklyProgress = 0.0;
            _activeWorkout = null;
            _workoutDay = 0;
          });
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Haftalık ilerleme yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _weeklyProgress = 0.0;
          _activeWorkout = null;
          _workoutDay = 0;
        });
      }
    }
  }

  // Antrenmanın kaçıncı gününde olduğunu hesapla
  Future<int> _calculateWorkoutDay(String userId, String workoutId) async {
    try {
      // Tüm antrenman ilerleme kayıtlarını getir
      final allProgress = await _progressService.getProgressInDateRange(
        userId: userId,
        workoutId: workoutId,
        startDate: DateTime(2020, 1, 1), // Çok eski bir tarih
        endDate: DateTime.now(),
      );

      if (allProgress.isEmpty) {
        // Eğer hiç kayıt yoksa, programın başlangıç tarihinden bugüne kadar geçen gün sayısını hesapla
        final activeWorkout = await _workoutService.getActiveWorkout(userId);
        if (activeWorkout != null) {
          final startDate = activeWorkout.createdAt;
          final today = DateTime.now();
          final daysDiff = today.difference(startDate).inDays;
          return daysDiff > 0 ? daysDiff : 1;
        }
        return 1;
      }

      // İlk antrenman gününü bul
      final firstDate = allProgress.first['date'] as String;
      final startDate = DateTime.parse(firstDate);
      final today = DateTime.now();
      final daysDiff = today.difference(startDate).inDays;

      // En az 1. gün olmalı
      return daysDiff > 0 ? daysDiff + 1 : 1;
    } catch (e) {
      debugPrint('Antrenman günü hesaplama hatası: $e');
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ModernBackground(
        child: SafeArea(
            child: RefreshIndicator(
              color: _cyanAccent,
          onRefresh: () async {
            await _loadUserProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER
                _buildHeader(),

                const SizedBox(height: 24),

                // 2. PROGRAM İLERLEMESİ (çember)
                _buildCircularProgress(),

                const SizedBox(height: 24),

                // 2b. GÜNLÜK KALORİ ÖZETİ
                CalorieSummaryCard(
                  dailyTarget: _dailyCalorieTarget,
                  caloriesBurned: _caloriesBurnedToday,
                  caloriesConsumed: _caloriesConsumedToday,
                  hasProfileData: _hasCalorieProfileData,
                  onRefresh: () {
                    if (_userProfile != null) {
                      _loadCalorieSummary(_userProfile!.id, _userProfile!);
                    }
                  },
                ),

                const SizedBox(height: 24),

                // 3. PLAN + BUGÜN ÖZET KARTI
                if (_activeGoal != null)
                  _buildPlanTodayCard()
                else
                  _buildTodaySummaryCard(),
                const SizedBox(height: 24),

                // 4. BUGÜNKÜ EGZERSİZLER LİSTESİ
                if (_shouldShowTodayExercisesList()) _buildTodayExercisesList(),
                if (_shouldShowTodayExercisesList()) const SizedBox(height: 24),

                // 5. AI VE ANALİZ ARAÇLARI
                const Text(
                  'AI ve Analiz Araçları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Ekipman Tanıma',
                        backgroundAsset: 'assets/images/ekipman5.jpg',
                        showIcon: false,
                        titleBelow: true,
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const EquipmentRecognitionScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.accessibility_new_rounded,
                        title: 'Sakatlık Analizi',
                        backgroundAsset: 'assets/images/sakatlık2.jpg',
                        showIcon: false,
                        titleBelow: true,
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const InjuryAssessmentScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildMiniCoachCard(),

                const SizedBox(height: 30),

                // 6. ANTRENMAN ARAÇLARI
                const Text(
                  'Antrenman Araçları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.timer_outlined,
                        title: 'Kronometre & Zamanlayıcı',
                        backgroundAsset: 'assets/images/kronometre.jpg',
                        showIcon: false,
                        titleBelow: true,
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const TimerStopwatchScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFeatureCard(
                        icon: Icons.fitness_center_outlined,
                        title: 'Güç\nTakibi',
                        backgroundAsset: 'assets/images/guc.jpg',
                        showIcon: false,
                        titleBelow: true,
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const StrengthTrackingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // REHABİLİTASYON PLANIM
                const Text(
                  'Rehabilitasyon Planım',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRehabPlanCard(),

                const SizedBox(height: 30),

                // 7. PROGRAMIM
                const Text(
                  'Programım',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildProgramCard(
                        title: 'Rehabilitasyon\nPlanım',
                        subtitle: _activeRehabPlan != null ? 'Aktif Plan' : 'Oluştur',
                        onTap: () {
                          if (_activeRehabPlan != null) {
                            Navigator.of(context).push(
                              NavigationHelper.createHomeExitRoute(
                                RehabPlanTrackerScreen(planId: _activeRehabPlan!.id),
                              ),
                            ).then((_) => _loadUserProfile());
                          } else {
                            Navigator.of(context).push(
                              NavigationHelper.createHomeExitRoute(
                                const InjuryAssessmentScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildProgramCard(
                        title: 'Antrenmanım',
                        subtitle: 'Kaydedilen Programlar',
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const WorkoutListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildProgramCard(
                        title: 'Fizyoterapi\nEgzersizleri',
                        subtitle: 'Esneme',
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const PhysicalTherapyExercisesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildProgramCard(
                        title: 'Tüm\nProgramlar',
                        subtitle: 'Tüm Antrenmanlar',
                        onTap: () {
                          Navigator.of(context).push(
                            NavigationHelper.createHomeExitRoute(
                              const ExerciseListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context)
                .push(
                  NavigationHelper.createHomeExitRoute(
                    const ProfileScreen(),
                  ),
                )
                .then((_) => _loadUserProfile());
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _userProfile?.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _userProfile!.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 30,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeGreeting(),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    _userName ?? 'Misafir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka plandaki gri halka
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 15,
              color: _cardColor,
            ),
          ),
          // İlerleme halkası (Cyan)
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: _weeklyProgress.clamp(0.0, 1.0),
              strokeWidth: 15,
              color: _cyanAccent,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Ortadaki Yazı
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(
                    NavigationHelper.createHomeExitRoute(
                      const DailyWorkoutTrackerScreen(),
                    ),
                  )
                  .then((_) => _loadUserProfile()); // Geri dönünce yenile
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Program ilerlemesi',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${(_weeklyProgress * 100).toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _weeklyProgress >= 1.0 ? 'Tamamlandı' : 'Devam Ediyor',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    final workoutName = _activeWorkout?.name ?? 'Aktif Antrenman Yok';
    final exerciseCount = _todaySessionExerciseCount();
    final dayText = _workoutDay > 0 ? 'Gün $_workoutDay' : 'Başlamadı';

    final todayWeekday = DateTime.now().weekday;
    final isWorkoutDay =
        _activeGoal?.workoutDays.contains(todayWeekday) ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const DailyWorkoutTrackerScreen(),
              ),
            )
            .then((_) => _loadUserProfile()); // Geri dönünce yenile
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cyanAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BUGÜN',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                if (isWorkoutDay)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center,
                            color: Colors.black87, size: 14),
                        SizedBox(width: 4),
                        Text('Antrenman Günü',
                            style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTodayStatItem('Antrenman', workoutName),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.black12), // Ayırıcı çizgi
                Expanded(
                  child: _buildTodayStatItem('Gün', dayText),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: Colors.black12), // Ayırıcı çizgi
                Expanded(
                  child: _buildTodayStatItem('Egzersiz', '$exerciseCount Adet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  bool _shouldShowTodayExercisesList() {
    if (_activeWorkout == null || _activeWorkout!.exercises.isEmpty) {
      return false;
    }

    final goal = _activeGoal;
    if (goal == null || goal.workoutDays.isEmpty) {
      return true;
    }

    return goal.workoutDays.contains(DateTime.now().weekday);
  }

  /// Bugünkü antrenman seansına düşen hareketler (kart sayacı ve aşağıdaki liste ile aynı bölümleme).
  List<WorkoutExercise> _todaySessionExercises() {
    final workout = _activeWorkout;
    if (workout == null || workout.exercises.isEmpty) return const [];

    final exercises = workout.exercises;
    final goal = _activeGoal;
    final todayWeekday = DateTime.now().weekday;
    final sortedWorkoutDays =
        goal != null ? (List<int>.from(goal.workoutDays)..sort()) : <int>[];

    if (sortedWorkoutDays.isNotEmpty) {
      final dayIndex = sortedWorkoutDays.indexOf(todayWeekday);
      if (dayIndex == -1) return const [];

      final exercisesPerDay =
          (exercises.length / sortedWorkoutDays.length).ceil();
      final startIdx = dayIndex * exercisesPerDay;
      return exercises.skip(startIdx).take(exercisesPerDay).toList();
    }

    final daysPerWeek = goal?.workoutDaysPerWeek ?? 3;
    final exercisesPerDay = (exercises.length / daysPerWeek).ceil();
    final dayIndex = (todayWeekday - 1) % daysPerWeek;
    final startIdx = dayIndex * exercisesPerDay;
    return exercises.skip(startIdx).take(exercisesPerDay).toList();
  }

  int _todaySessionExerciseCount() => _todaySessionExercises().length;

  bool get _canStartTodayWorkout =>
      _activeWorkout != null && _todaySessionExercises().isNotEmpty;

  void _openAiChat({String? initialMessage}) {
    Navigator.of(context).push(
      NavigationHelper.createHomeExitRoute(
        AiChatScreen(initialMessage: initialMessage),
      ),
    );
  }

  void _openTodayWorkoutFromCoach() {
    Navigator.of(context).push(
      NavigationHelper.createHomeExitRoute(
        DailyWorkoutTrackerScreen(initialWorkoutId: _activeWorkout?.id),
      ),
    );
  }

  Widget _buildMiniCoachCard() {
    final summary = AiCoachContextService.buildMiniCoachSummary(
      workout: _activeWorkout,
      goal: _activeGoal,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cyanAccent.withValues(alpha: 0.12), _cardColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openAiChat(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SvgPicture.asset(
                            'assets/images/AI.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Koç',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _cyanAccent, size: 24),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniCoachQuickButton(
                  label: 'Bugün ne yapmalıyım?',
                  filled: false,
                  onTap: () => _openAiChat(
                    initialMessage: 'Bugün ne yapmalıyım?',
                  ),
                ),
              ),
              if (_canStartTodayWorkout) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniCoachQuickButton(
                    label: 'Antrenmana başla',
                    filled: true,
                    onTap: _openTodayWorkoutFromCoach,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCoachQuickButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: filled
                ? _cyanAccent.withValues(alpha: 0.18)
                : _backgroundColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled
                  ? _cyanAccent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: filled ? Colors.white : _cyanAccent,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? backgroundAsset,
    bool showIcon = true,
    bool titleBelow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              image: backgroundAsset != null
                  ? DecorationImage(
                      image: AssetImage(backgroundAsset),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: backgroundAsset != null && (showIcon || !titleBelow)
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  showIcon
                      ? Icon(icon, color: _cyanAccent, size: 32)
                      : const SizedBox.shrink(),
                  if (!titleBelow)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (titleBelow) ...[
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── KİŞİSEL PLAN KARTI ───

  Widget _buildPlanTodayCard() {
    final goal = _activeGoal!;
    final Color goalColor;
    final workoutName = _activeWorkout?.name ?? goal.goalTypeDisplayName;
    final exerciseCount = _todaySessionExerciseCount();
    final dayText = _workoutDay > 0 ? 'Gün $_workoutDay' : 'Başlamadı';
    final weeksText = '${_activeWorkout?.weeks ?? goal.programWeeks} hafta';
    final todayWeekday = DateTime.now().weekday;
    final isWorkoutDay = goal.workoutDays.contains(todayWeekday);
    final todayStatus = isWorkoutDay ? 'Aktif' : 'Dinlenme';

    switch (goal.goalType) {
      case 'weight_loss':
        goalColor = Colors.orangeAccent;
        break;
      case 'muscle_gain':
        goalColor = _cyanAccent;
        break;
      case 'physiotherapy':
        goalColor = Colors.greenAccent;
        break;
      default:
        goalColor = Colors.pinkAccent;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => const DailyWorkoutTrackerScreen(),
              ),
            )
            .then((_) => _loadUserProfile());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              goalColor.withValues(alpha: 0.14),
              _cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: goalColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: goalColor.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Senin Planın',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workoutName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${goal.workoutDaysPerWeek} gün/hafta • $weeksText',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: goalColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        goal.experienceLevelDisplayName,
                        style: TextStyle(
                          color: goalColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white38, size: 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPlanTodayStatItem('Bugün', todayStatus),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPlanTodayStatItem('Gün', dayText),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPlanTodayStatItem('Hareket', '$exerciseCount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTodayStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── BUGÜNKÜ EGZERSİZLER LİSTESİ ───

  Widget _buildTodayExercisesList() {
    final todayExercises = _todaySessionExercises();
    if (todayExercises.isEmpty) return const SizedBox.shrink();
    return _buildTodayExercisesAccordion(todayExercises);
  }

  Widget _buildTodayExercisesAccordion(List<WorkoutExercise> todayExercises) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _isTodayExercisesExpanded = !_isTodayExercisesExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bugünkü Egzersizlerin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isTodayExercisesExpanded
                                ? 'Listeyi gizlemek için dokun'
                                : 'Listeyi görmek için dokun',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _cyanAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todayExercises.length} hareket',
                        style: TextStyle(
                          color: _cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _isTodayExercisesExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _cyanAccent,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _isTodayExercisesExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 12),
                  ...todayExercises.asMap().entries.map((entry) {
                    final i = entry.key;
                    final ex = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _backgroundColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _cyanAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: _cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.exerciseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  workoutExerciseVolumeText(ex),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRehabPlanCard() {
    if (_activeRehabPlan == null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            NavigationHelper.createHomeExitRoute(const InjuryAssessmentScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Icon(Icons.healing, color: _cyanAccent, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Henüz rehab planınız yok',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sakatlık analizi yapıp doktor önerilerine göre program oluşturun',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      );
    }

    final plan = _activeRehabPlan!;
    final percent = (_rehabProgress * 100).toInt();

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              NavigationHelper.createHomeExitRoute(
                RehabPlanTrackerScreen(planId: plan.id),
              ),
            )
            .then((_) => _loadUserProfile());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '%$percent',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.bodyPart} • Gün $_rehabCompletedDays/${plan.totalDays}',
              style: TextStyle(color: Colors.grey[300], fontSize: 13),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _rehabProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.black26,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Sol taraf dekoratif çizgi
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: _cyanAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
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
}
