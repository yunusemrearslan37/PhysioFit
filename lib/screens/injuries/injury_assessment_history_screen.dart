import 'package:flutter/material.dart';
import '../../models/injury_assessment.dart';
import '../../services/auth_service.dart';
import '../../services/injury_assessment_service.dart';
import '../../widgets/modern_background.dart';
import 'create_rehab_program_screen.dart';

class InjuryAssessmentHistoryScreen extends StatefulWidget {
  const InjuryAssessmentHistoryScreen({super.key});

  @override
  State<InjuryAssessmentHistoryScreen> createState() =>
      _InjuryAssessmentHistoryScreenState();
}

class _InjuryAssessmentHistoryScreenState
    extends State<InjuryAssessmentHistoryScreen> {
  final _authService = AuthService();
  final _assessmentService = InjuryAssessmentService();

  List<InjuryAssessment> _assessments = [];
  bool _isLoading = true;

  final Color _cardColor = const Color(0x88121A2F);
  final Color _dialogColor = const Color(0xFF121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final list = await _assessmentService.getUserAssessments(user.id);
      if (!mounted) return;
      setState(() {
        _assessments = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş yüklenemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _scoreColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  void _openCreateRehabProgram(InjuryAssessment assessment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateRehabProgramScreen(
          bodyPart: assessment.bodyPart,
          assessmentId: assessment.id,
          suggestedExerciseNames: assessment.recommendedExerciseIds,
        ),
      ),
    );
  }

  Color _recoveryColor(String? status) {
    switch (status) {
      case 'geçti':
        return Colors.green;
      case 'devam_ediyor':
        return Colors.orange;
      default:
        return _cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        title: const Text('Analiz Geçmişi'),
        backgroundColor: _cardColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ModernBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
            : _assessments.isEmpty
                ? Center(
                    child: Text(
                      'Henüz kayıtlı analiz yok',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_assessments.length >= 2) _buildTrendCard(),
                      const SizedBox(height: 16),
                      ..._assessments.map(_buildHistoryCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTrendCard() {
    final recent = _assessments.take(5).toList();
    final latest = recent.first.severityScore;
    final oldest = recent.last.severityScore;
    final diff = latest - oldest;
    final trendText = diff < 0
        ? 'Son analizlerde ${diff.abs()} puan iyileşme'
        : diff > 0
            ? 'Son analizlerde $diff puan artış'
            : 'Puan değişimi yok';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dialogColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puan Trendi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(trendText, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: recent.reversed.map((a) {
              final h = (a.severityScore / 100 * 60).clamp(8.0, 60.0);
              return Column(
                children: [
                  Container(
                    width: 18,
                    height: h,
                    decoration: BoxDecoration(
                      color: _scoreColor(a.severityScore),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${a.severityScore}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(InjuryAssessment assessment) {
    final redFlags = assessment.functionalityTest['red_flags'];
    final hasRedFlag = redFlags is List && redFlags.isNotEmpty;
    final status = assessment.recoveryStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'geçti'
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.grey[800]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assessment.bodyPart,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _scoreColor(assessment.severityScore).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${assessment.severityScore}/100',
                  style: TextStyle(
                    color: _scoreColor(assessment.severityScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(assessment.createdAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          if (assessment.recommendedInjuryType != null) ...[
            const SizedBox(height: 8),
            Text(
              assessment.recommendedInjuryType!,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
          if (status != null && status != 'aktif') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _recoveryColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Durum: ${assessment.recoveryStatusDisplay}',
                style: TextStyle(
                  color: _recoveryColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (hasRedFlag) ...[
            const SizedBox(height: 8),
            const Text(
              'Kırmızı bayrak işaretlendi',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          if (assessment.id != null &&
              assessment.severityScore < 70 &&
              !hasRedFlag &&
              status != 'geçti') ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _openCreateRehabProgram(assessment),
              icon: const Icon(Icons.playlist_add, size: 18),
              label: const Text('Rehab programı oluştur'),
              style: TextButton.styleFrom(foregroundColor: _cyanAccent),
            ),
          ],
        ],
      ),
    );
  }
}
