import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/user_metrics_service.dart';
import '../../models/user_profile.dart';
import '../../models/user_metric.dart';
import '../../widgets/modern_background.dart';
import '../auth/login_screen.dart';
import 'profile_edit_screen.dart';
import 'change_password_screen.dart';
import 'settings_screen.dart';
import 'update_metrics_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _metricsService = UserMetricsService();

  UserProfile? _userProfile;
  UserMetric? _latestMetric;
  bool _isLoading = true;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _dialogColor = const Color(0xFF121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _authService.getUserProfile();
      UserMetric? metric;
      if (profile != null) {
        metric = await _metricsService.getLatestMetric(profile.id);
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _latestMetric = metric;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil yüklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış hatası: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Profil',
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
            : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Hesap'),
                      _buildMenuCard(
                        icon: Icons.person_outline,
                        title: 'Profil Ayarları',
                        subtitle: 'Fotoğraf, cinsiyet ve kişisel bilgiler',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProfileEditScreen(),
                            ),
                          );
                          _loadData();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuCard(
                        icon: Icons.settings_outlined,
                        title: 'Ayarlar',
                        subtitle: 'Gizlilik, bildirim ve hesap',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_authService.canChangePassword)
                        _buildMenuCard(
                          icon: Icons.lock_outline,
                          title: 'Şifre Güncelle',
                          subtitle: 'Hesap şifrenizi değiştirin',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                      if (_authService.canChangePassword) const SizedBox(height: 8),
                      _buildMenuCard(
                        icon: Icons.monitor_weight_outlined,
                        title: 'Boy & Kilo Güncelle',
                        subtitle: _metricsSubtitle(),
                        onTap: () async {
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => const UpdateMetricsScreen(),
                            ),
                          );
                          if (updated == true) _loadData();
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildLogoutCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  String _metricsSubtitle() {
    if (_latestMetric?.height != null && _latestMetric?.weight != null) {
      return '${_latestMetric!.height!.toStringAsFixed(0)} cm • ${_latestMetric!.weight!.toStringAsFixed(1)} kg';
    }
    return 'Boy ve kilo bilgilerinizi güncelleyin';
  }

  Widget _buildProfileHeader() {
    final name = _userProfile?.name?.isNotEmpty == true
        ? _userProfile!.name!
        : (_userProfile?.email.split('@').first ?? 'Kullanıcı');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyanAccent.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _userProfile?.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _userProfile!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 36,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white70, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (_userProfile?.age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_userProfile!.age} yaşında',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final accent = iconColor ?? _cyanAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Text(
              'Çıkış Yap',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
