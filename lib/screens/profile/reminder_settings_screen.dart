import 'package:flutter/material.dart';

import '../../models/notification_preferences.dart';
import '../../services/notification_preferences_service.dart';
import '../../widgets/modern_background.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _service = NotificationPreferencesService();
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  NotificationPreferences _workout = const NotificationPreferences();
  WaterReminderSettings _water = const WaterReminderSettings();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getPreferences(),
        _service.getWaterReminder(),
      ]);
      if (!mounted) return;
      setState(() {
        _workout = results[0] as NotificationPreferences;
        _water = results[1] as WaterReminderSettings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Ayarlar açılamadı: $e');
    }
  }

  Future<void> _pickTime({required bool workout}) async {
    final current = workout
        ? TimeOfDay(hour: _workout.reminderHour, minute: _workout.reminderMinute)
        : TimeOfDay(hour: _water.hour, minute: _water.minute);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;
    setState(() {
      if (workout) {
        _workout = _workout.copyWith(
          reminderHour: picked.hour,
          reminderMinute: picked.minute,
        );
      } else {
        _water = WaterReminderSettings(
          enabled: _water.enabled,
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await _service.updatePreferences(_workout);
      await _service.syncLocalWorkoutReminders(preferences: saved);
      await _service.saveWaterReminder(_water);
      await _service.applyWaterReminder(_water);
      if (!mounted) return;
      _showMessage('Hatırlatmalar güncellendi');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _format(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Hatırlatmalar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModernBackground(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: _cyanAccent))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    title: 'Antrenman',
                    subtitle: 'Seçtiğin antrenman günlerinde',
                    enabled: _workout.workoutRemindersEnabled,
                    time: _format(_workout.reminderHour, _workout.reminderMinute),
                    onToggle: (value) {
                      setState(() {
                        _workout = _workout.copyWith(workoutRemindersEnabled: value);
                      });
                    },
                    onTime: () => _pickTime(workout: true),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Su',
                    subtitle: 'Her gün bir kez',
                    enabled: _water.enabled,
                    time: _format(_water.hour, _water.minute),
                    onToggle: (value) {
                      setState(() {
                        _water = WaterReminderSettings(
                          enabled: value,
                          hour: _water.hour,
                          minute: _water.minute,
                        );
                      });
                    },
                    onTime: () => _pickTime(workout: false),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyanAccent,
                        foregroundColor: const Color(0xFF050914),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_saving ? 'Kaydediliyor' : 'Kaydet'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required bool enabled,
    required String time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTime,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeColor: _cyanAccent,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: enabled ? onTime : null,
              child: Text(
                time,
                style: TextStyle(
                  color: enabled ? _cyanAccent : Colors.white38,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
