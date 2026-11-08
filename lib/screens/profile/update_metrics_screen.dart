import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_metrics_service.dart';
import '../../models/user_metric.dart';
import '../../widgets/modern_background.dart';

class UpdateMetricsScreen extends StatefulWidget {
  const UpdateMetricsScreen({super.key});

  @override
  State<UpdateMetricsScreen> createState() => _UpdateMetricsScreenState();
}

class _UpdateMetricsScreenState extends State<UpdateMetricsScreen> {
  final _authService = AuthService();
  final _metricsService = UserMetricsService();
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserMetric? _latestMetric;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    try {
      final profile = await _authService.getUserProfile();
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final metric = await _metricsService.getLatestMetric(profile.id);
      if (mounted) {
        setState(() {
          _latestMetric = metric;
          if (metric?.height != null) {
            _heightController.text = metric!.height!.toStringAsFixed(0);
          }
          if (metric?.weight != null) {
            _weightController.text = metric!.weight!.toStringAsFixed(1);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Metrikler yüklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveMetrics() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = await _authService.getUserProfile();
    if (profile == null) return;

    setState(() => _isSaving = true);

    try {
      final height = double.parse(_heightController.text.trim());
      final weight = double.parse(_weightController.text.trim());

      final metric = await _metricsService.addMetric(
        userId: profile.id,
        height: height,
        weight: weight,
      );

      if (mounted) {
        setState(() {
          _latestMetric = metric;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boy ve kilo bilgileriniz güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double? get _previewBmi {
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    if (h == null || w == null || h <= 0) return null;
    final heightInMeters = h / 100;
    return w / (heightInMeters * heightInMeters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Boy & Kilo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModernBackground(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_cyanAccent),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Fiziksel ölçülerinizi güncelleyin. Yeni kayıt geçmişinize eklenir.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _heightController,
                        label: 'Boy (cm)',
                        icon: Icons.height_rounded,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Boy gerekli';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 100 || parsed > 250) {
                            return 'Geçerli bir boy girin (100-250 cm)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _weightController,
                        label: 'Kilo (kg)',
                        icon: Icons.monitor_weight_outlined,
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kilo gerekli';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 30 || parsed > 300) {
                            return 'Geçerli bir kilo girin (30-300 kg)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_previewBmi != null) _buildBmiCard(),
                      if (_latestMetric?.recordedAt != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Son güncelleme: ${_formatDate(_latestMetric!.recordedAt)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveMetrics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : const Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBmiCard() {
    final bmi = _previewBmi!;
    String category;
    if (bmi < 18.5) {
      category = 'Zayıf';
    } else if (bmi < 25) {
      category = 'Normal';
    } else if (bmi < 30) {
      category = 'Fazla Kilolu';
    } else {
      category = 'Obez';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: _cyanAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'VKİ: ${bmi.toStringAsFixed(1)} ($category)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: _cyanAccent, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
