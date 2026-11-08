import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/modern_background.dart';
import '../auth/login_screen.dart';
import 'reminder_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A2F),
        surfaceTintColor: Colors.transparent,
        title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Hesabınız ve profil kaydınız silinir. Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hesabımı Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openText({required String title, required String body}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SettingsTextScreen(title: title, body: body),
      ),
    );
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
          'Ayarlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModernBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Gizlilik',
                  subtitle: 'Hangi veriler saklanır',
                  onTap: () => _openText(title: 'Gizlilik', body: _privacyText),
                ),
                const SizedBox(height: 8),
                _tile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Tıbbi feragat',
                  subtitle: 'Bu uygulama teşhis koymaz',
                  onTap: () => _openText(title: 'Tıbbi feragat', body: _disclaimerText),
                ),
                const SizedBox(height: 8),
                _tile(
                  icon: Icons.notifications_none,
                  title: 'Bildirimler',
                  subtitle: 'Antrenman ve su saati',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReminderSettingsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _tile(
                  icon: Icons.info_outline,
                  title: 'Sürüm',
                  subtitle: '1.0.0 (1)',
                  onTap: null,
                ),
                const SizedBox(height: 28),
                _tile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Hesabımı sil',
                  subtitle: 'Profil kaydı silinir ve çıkış yapılır',
                  iconColor: Colors.red,
                  onTap: _isDeleting ? null : _deleteAccount,
                ),
              ],
            ),
            if (_isDeleting)
              const ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? _cyanAccent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTextScreen extends StatelessWidget {
  const _SettingsTextScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050914),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ModernBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              body,
              style: const TextStyle(color: Colors.white70, height: 1.45, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

const _privacyText = '''
PhysioFit hesabına bağlı olarak e-posta, ad, boy, kilo, antrenman, sakatlık notu ve koç sohbetini saklar.

Antrenman ve profil verisi Supabase üzerinde durur. Koça yazdığın mesaj, yanıt üretmek için Google Gemini servisine gider. Bildirimler için Firebase kullanılır. Kamera ile ekipman tanıma telefonda çalışır; fotoğraf sunucuya yüklenmez.

Su hatırlatma saati yalnızca bu telefonda saklanır. Hesabını sildiğinde profil kaydın silinir ve oturumun kapanır.
''';

const _disclaimerText = '''
PhysioFit bir antrenman ve bilgilendirme uygulamasıdır. Tıbbi teşhis, tedavi veya doktor muayenesi yerine geçmez.

Sakatlık analizi, rehabilitasyon önerileri, kalori hesabı ve yapay zekâ koçu genel bilgi verir. Ağrı, uyuşma, şişlik veya nefes darlığı varsa hareketi bırak ve bir sağlık uzmanına başvur.

İyileşme süreleri tahmini genel bilgidir. Kişiye özel tıbbi süre değildir.
''';
