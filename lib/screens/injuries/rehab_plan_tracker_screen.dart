import 'package:flutter/material.dart';
import '../../models/rehab_plan.dart';
import '../../services/auth_service.dart';
import '../../services/rehab_plan_service.dart';
import '../../services/user_limitations_service.dart';
import '../../widgets/modern_background.dart';
import 'create_rehab_program_screen.dart';
import 'injury_assessment_screen.dart';

class RehabPlanTrackerScreen extends StatefulWidget {
  const RehabPlanTrackerScreen({
    super.key,
    required this.planId,
  });

  final String planId;

  @override
  State<RehabPlanTrackerScreen> createState() => _RehabPlanTrackerScreenState();
}

class _RehabPlanTrackerScreenState extends State<RehabPlanTrackerScreen> {
  final _rehabService = RehabPlanService();
  final _limitationsService = UserLimitationsService();
  final _authService = AuthService();

  RehabPlan? _plan;
  Set<int> _completedDays = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _recoveryDialogShown = false;

  static const Color _cardColor = Color(0x88121A2F);
  static const Color _dialogColor = Color(0xFF121A2F);
  static const Color _cyanAccent = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final plan = await _rehabService.getPlanById(widget.planId);
      if (plan == null) throw Exception('Plan bulunamadı');

      final days = await _rehabService.getCompletedDays(
        userId: user.id,
        rehabPlanId: plan.id,
      );

      if (!mounted) return;
      setState(() {
        _plan = plan;
        _completedDays = days;
        _isLoading = false;
      });

      if (_isPlanComplete && plan.recoveryStatus == 'aktif' && !_recoveryDialogShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRecoveryDialog());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yüklenemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool get _isPlanComplete {
    final plan = _plan;
    if (plan == null) return false;
    return _completedDays.length >= plan.totalDays;
  }

  Future<void> _markDayComplete(int dayNumber) async {
    final user = _authService.currentUser;
    final plan = _plan;
    if (user == null || plan == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _rehabService.markDayComplete(
        userId: user.id,
        rehabPlanId: plan.id,
        dayNumber: dayNumber,
      );
      if (!mounted) return;
      setState(() {
        _completedDays = {..._completedDays, dayNumber};
        _isSaving = false;
      });

      if (_isPlanComplete && plan.recoveryStatus == 'aktif') {
        await _showRecoveryDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showRecoveryDialog() async {
    if (_recoveryDialogShown || !mounted || _plan == null) return;
    _recoveryDialogShown = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Program Tamamlandı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${_plan!.bodyPart} bölgesindeki sakatlığınız geçti mi?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('devam_ediyor'),
            child: const Text('Hayır, devam ediyor', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('geçti'),
            child: const Text('Evet, geçti', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (result == null) {
      _recoveryDialogShown = false;
      return;
    }

    await _saveRecoveryStatus(result);
  }

  Future<void> _saveRecoveryStatus(String status) async {
    final plan = _plan;
    if (plan == null) return;

    setState(() => _isSaving = true);
    try {
      await _rehabService.updateRecoveryStatus(
        rehabPlanId: plan.id,
        status: status,
        assessmentId: plan.assessmentId,
      );

      final user = _authService.currentUser;
      if (status == 'geçti' && user != null) {
        await _limitationsService.deactivateLimitationsForBodyPart(
          userId: user.id,
          bodyPart: plan.bodyPart,
        );
      }

      if (!mounted) return;
      await _load();

      final message = status == 'geçti'
          ? 'Sakatlık geçti olarak kaydedildi.'
          : 'Durum kaydedildi. Yeni analiz yapabilirsiniz.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );

      if (status == 'devam_ediyor' && mounted) {
        final goNew = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _dialogColor,
            surfaceTintColor: Colors.transparent,
            title: const Text('Yeni Analiz', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Yeni sakatlık analizi yapmak ister misiniz?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Sonra', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Analiz Yap', style: TextStyle(color: _cyanAccent)),
              ),
            ],
          ),
        );
        if (goNew == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const InjuryAssessmentScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _recoveryDialogShown = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        title: const Text('Rehabilitasyon Planım'),
        backgroundColor: _cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ModernBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _cyanAccent))
            : _plan == null
                ? const Center(child: Text('Plan bulunamadı', style: TextStyle(color: Colors.white70)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final plan = _plan!;
    final progress = plan.totalDays == 0 ? 0.0 : _completedDays.length / plan.totalDays;
    final planFinished = plan.recoveryStatus != 'aktif';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _dialogColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              Text('${plan.bodyPart} • ${_completedDays.length}/${plan.totalDays} gün',
                  style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(_cyanAccent),
                ),
              ),
              if (planFinished) ...[
                const SizedBox(height: 10),
                Text(
                  'Durum: ${plan.recoveryStatusDisplay}',
                  style: TextStyle(
                    color: plan.isRecovered ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Program Hareketleri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...plan.exercises.map((ex) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(ex.description, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${ex.sets} set × ${ex.reps ?? '-'} tekrar',
                      style: TextStyle(color: _cyanAccent, fontSize: 12)),
                ],
              ),
            )),
        const SizedBox(height: 16),
        const Text('Günlük Takip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(plan.totalDays, (index) {
          final day = index + 1;
          final isDone = _completedDays.contains(day);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDone ? Colors.green.withValues(alpha: 0.1) : _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDone ? Colors.green : Colors.grey[800]!),
            ),
            child: Row(
              children: [
                Text('Gün $day', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!isDone && !planFinished)
                  TextButton(
                    onPressed: _isSaving ? null : () => _markDayComplete(day),
                    child: const Text('Tamamladım'),
                  )
                else if (isDone)
                  const Text('✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
        if (_isPlanComplete && plan.recoveryStatus == 'aktif') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showRecoveryDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Sakatlık Durumunu Bildir'),
            ),
          ),
        ],
        if (planFinished && !plan.isRecovered) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateRehabProgramScreen(
                    bodyPart: plan.bodyPart,
                    assessmentId: plan.assessmentId,
                  ),
                ),
              );
            },
            child: Text('Yeni Program Oluştur', style: TextStyle(color: _cyanAccent)),
          ),
        ],
      ],
    );
  }
}
