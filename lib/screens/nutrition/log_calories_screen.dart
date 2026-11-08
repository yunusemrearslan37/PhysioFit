import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/daily_nutrition_service.dart';
import '../../widgets/modern_background.dart';

class LogCaloriesScreen extends StatefulWidget {
  const LogCaloriesScreen({super.key, this.initialCalories = 0});

  final int initialCalories;

  @override
  State<LogCaloriesScreen> createState() => _LogCaloriesScreenState();
}

class _LogCaloriesScreenState extends State<LogCaloriesScreen> {
  final _authService = AuthService();
  final _nutritionService = DailyNutritionService();
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  bool _isSaving = false;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    if (widget.initialCalories > 0) {
      _caloriesController.text = widget.initialCalories.toString();
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = await _authService.getUserProfile();
    if (profile == null) return;

    setState(() => _isSaving = true);
    try {
      final calories = int.parse(_caloriesController.text.trim());
      await _nutritionService.upsert(
        userId: profile.id,
        date: DateTime.now(),
        caloriesConsumed: calories,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt hatası: $e'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kalori Girişi', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cyanAccent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugün ne kadar kalori aldınız?',
                          style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            suffixText: 'kcal',
                            suffixStyle: TextStyle(color: _cyanAccent, fontSize: 18),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _cyanAccent.withValues(alpha: 0.4)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _cyanAccent),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kalori miktarı girin';
                            }
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 0 || n > 15000) {
                              return 'Geçerli bir değer girin (0–15000)';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tahmini değer girebilirsiniz. Detaylı beslenme takibi ileride eklenecek.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Kaydet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
