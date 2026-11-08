import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/modern_background.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  UserProfile? _userProfile;
  String? _selectedGender;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  File? _selectedImage;

  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _selectedGender = profile?.gender;
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _isUploadingImage = _selectedImage != null;
    });

    try {
      String? avatarUrl;

      if (_selectedImage != null && _userProfile != null) {
        avatarUrl = await _storageService.uploadProfileImage(
          userId: _userProfile!.id,
          imageFile: _selectedImage!,
        );
      }

      await _authService.updateUserProfile(
        gender: _selectedGender,
        avatarUrl: avatarUrl ?? _userProfile?.avatarUrl,
      );

      await _loadUserProfile();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _isUploadingImage = false;
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Profil Ayarları',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: _cyanAccent),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserProfile();
              },
            ),
        ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _cyanAccent, width: 3),
                                ),
                                child: ClipOval(
                                  child: _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                        )
                                      : _userProfile?.avatarUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: _userProfile!.avatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.white70,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.white70,
                                            ),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _cyanAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isUploadingImage
                                        ? const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.black),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        label: 'E-posta',
                        value: _userProfile?.email ?? 'Bilinmiyor',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        label: 'Ad Soyad',
                        value: _userProfile?.name ?? 'Belirtilmemiş',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.cake_outlined,
                        label: 'Yaş',
                        value: _userProfile?.age != null
                            ? '${_userProfile!.age} yaşında'
                            : 'Belirtilmemiş',
                      ),
                      const SizedBox(height: 16),
                      _buildGenderCard(),
                      const SizedBox(height: 32),
                      if (_userProfile != null)
                        _buildInfoCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'Kayıt Tarihi',
                          value: _formatDate(_userProfile!.createdAt),
                        ),
                      const SizedBox(height: 32),
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _uploadAndSaveProfile,
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _cyanAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: _cyanAccent, size: 24),
              const SizedBox(width: 16),
              const Text(
                'Cinsiyet',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            Text(
              _selectedGender ?? 'Belirtilmemiş',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Row(
              children: [
                Expanded(child: _buildGenderOption('Erkek', 'Erkek')),
                const SizedBox(width: 12),
                Expanded(child: _buildGenderOption('Kadın', 'Kadın')),
                const SizedBox(width: 12),
                Expanded(child: _buildGenderOption('Diğer', 'Diğer')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent : _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _cyanAccent : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
