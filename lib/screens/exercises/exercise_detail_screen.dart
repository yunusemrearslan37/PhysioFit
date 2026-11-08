import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/modern_background.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _exerciseService = ExerciseService();
  final _storageService = StorageService();
  Exercise? _exercise;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  bool get _isCardioExercise =>
      (_exercise?.category ?? '').trim().toLowerCase() == 'cardio';

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercise = await _exerciseService.getExerciseById(widget.exerciseId);
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });

      // Kardiyovasküler (Cardio) egzersizlerde video hiç gösterilmez.
      if (_isCardioExercise) {
        _videoController?.dispose();
        _videoController = null;
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
            _hasVideoError = false;
          });
        }
        return;
      }

      // Sadece assets'ten video çek (Supabase'e bulaşmadan)
      final assetPath = _storageService.getExerciseAnimationAssetPath(
        exerciseName: exercise!.name,
        category: exercise.category,
      );
      
      if (assetPath != null && assetPath.isNotEmpty) {
        _initializeVideo(assetPath, isAsset: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Egzersiz yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeVideo(String videoPath, {bool isAsset = false}) async {
    try {
      _videoController?.dispose();
      
      // Asset'ten mi yoksa network'ten mi yükleneceğini belirle
      if (isAsset) {
        debugPrint('Asset video yükleniyor: $videoPath');
        // VideoPlayerController.asset() tam asset path'i bekliyor (assets/ ile başlamalı)
        _videoController = VideoPlayerController.asset(videoPath);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      }
      
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _hasVideoError = false;
        });
        _videoController!.setLooping(true);
        
        // Video durumu değişikliklerini dinle
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
        
        _videoController!.play();
        debugPrint('Video başarıyla yüklendi ve oynatılıyor: $videoPath');
      }
    } catch (e, stackTrace) {
      debugPrint('Video yüklenirken hata: $e, Path: $videoPath');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _isVideoInitialized = false;
        });
      }
    }
  }

  String _getDifficultyText(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return 'Belirtilmemiş';
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF050914);
    final cardColor = const Color(0x88121A2F);
    final cyanAccent = const Color(0xFF00E5FF);
    final textGrey = const Color(0xFFB0B3B8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Nasıl Yapılır?',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: cardColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ModernBackground(
        child: _isLoading
            ? Center(
              child: CircularProgressIndicator(color: cyanAccent),
            )
          : _exercise == null
              ? Center(
                  child: Text(
                    'Egzersiz bulunamadı',
                    style: TextStyle(color: textGrey),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Oynatıcı
                      _buildVideoPlayer(cardColor, cyanAccent, textGrey),
                      // Açıklama ve Detaylar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık
                            Text(
                              _exercise!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Zorluk ve kategori
                            Row(
                              children: [
                                if (_exercise!.difficulty != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(_exercise!.difficulty)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getDifficultyText(_exercise!.difficulty),
                                      style: TextStyle(
                                        color: _getDifficultyColor(_exercise!.difficulty),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (_exercise!.category != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _exercise!.category!,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Önce yapılış rehberi (detaylı)
                            _buildHowToGuideSection(
                              cardColor: cardColor,
                              cyanAccent: cyanAccent,
                              textGrey: textGrey,
                            ),

                            const SizedBox(height: 24),

                            // Açıklama
                            if (_exercise!.description != null &&
                                _exercise!.description!.trim().isNotEmpty) ...[
                              Text(
                                'Genel bilgi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _exercise!.description!,
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 16,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Kas grupları
                            if (_exercise!.muscleGroups != null &&
                                _exercise!.muscleGroups!.isNotEmpty) ...[
                              Text(
                                'Hedef kas grupları',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _exercise!.muscleGroups!.map((muscle) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      muscle,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  /// "Nasıl yapılır" ana bölümü: adım kartları, ekipman, çok satırlı talimat, güvenlik notu.
  Widget _buildHowToGuideSection({
    required Color cardColor,
    required Color cyanAccent,
    required Color textGrey,
  }) {
    final ex = _exercise!;
    final steps = ex.instructions ?? const <String>[];
    final hasSteps = steps.where((s) => s.trim().isNotEmpty).isNotEmpty;
    final equipment = ex.equipmentType?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cyanAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cyanAccent.withOpacity(0.25)),
              ),
              child: Icon(Icons.play_lesson_outlined, color: cyanAccent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yapılış rehberi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isCardioExercise
                        ? 'Isınmış olduğunuzdan emin olun. Tempoyu konuşabileceğiniz şiddette tutun; ağrıda durun.'
                        : 'Aşağıdaki sırayı izleyin. Gövdeyi sabitleyin, kontrollü iniş yapın ve eklemleri kilitlemeyin.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (equipment != null && equipment.isNotEmpty) ...[
          const SizedBox(height: 16),
          _howToMetaRow(
            icon: Icons.sports_gymnastics,
            label: 'Ekipman',
            value: equipment,
            cardColor: cardColor,
            cyanAccent: cyanAccent,
            textGrey: textGrey,
          ),
        ],
        const SizedBox(height: 16),
        if (hasSteps) ...[
          ...steps
              .where((s) => s.trim().isNotEmpty)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _howToStepCard(
                    stepIndex: e.key + 1,
                    fullText: e.value.trim(),
                    cardColor: cardColor,
                    cyanAccent: cyanAccent,
                    textGrey: textGrey,
                  ),
                ),
              ),
          const SizedBox(height: 8),
          _howToSafetyTipCard(cardColor: cardColor, textGrey: textGrey),
        ] else
          _howToEmptyInstructions(
            ex: ex,
            cardColor: cardColor,
            cyanAccent: cyanAccent,
            textGrey: textGrey,
          ),
      ],
    );
  }

  Widget _howToMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required Color cardColor,
    required Color cyanAccent,
    required Color textGrey,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cyanAccent, size: 22),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: textGrey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tek adım: başlık satırı + ana metin; metin içinde \\n ile alt maddeler.
  Widget _howToStepCard({
    required int stepIndex,
    required String fullText,
    required Color cardColor,
    required Color cyanAccent,
    required Color textGrey,
  }) {
    final lines = fullText
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final headline = lines.isNotEmpty ? lines.first : fullText;
    final sublines = lines.length > 1 ? lines.sublist(1) : const <String>[];

    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: cyanAccent.withOpacity(0.9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adım $stepIndex',
                      style: TextStyle(
                        color: cyanAccent.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sublines.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...sublines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.arrow_right_alt_rounded,
                                  size: 18,
                                  color: cyanAccent.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _howToSafetyTipCard({
    required Color cardColor,
    required Color textGrey,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1520).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined,
              color: Colors.amber.shade200, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güvenli form',
                  style: TextStyle(
                    color: Colors.amber.shade100,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Omurga ve eklemler için doğal dizilimi koruyun. Keskin ağrı, baş dönmesi veya nefes darlığında durun.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _howToEmptyInstructions({
    required Exercise ex,
    required Color cardColor,
    required Color cyanAccent,
    required Color textGrey,
  }) {
    final hasDesc = ex.description != null && ex.description!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasDesc)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cyanAccent.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: cyanAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isCardioExercise
                        ? 'Bu kardiyo hareketi için aşağıdaki genel bilgi bölümünü kullanın. Adım adım liste veritabanına eklendiğinde burada görünecektir.'
                        : 'Adım adım talimat henüz eklenmemiş; üstteki videoyu izleyerek formu uygulayın. Metinler Supabase’de güncellenebilir.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _howToSafetyTipCard(cardColor: cardColor, textGrey: textGrey),
      ],
    );
  }

  Widget _buildVideoPlayer(Color cardColor, Color cyanAccent, Color textGrey) {
    // Kardiyovasküler egzersizlerde video alanını tamamen kaldır.
    if (_isCardioExercise) {
      return const SizedBox.shrink();
    }

    // Sadece assets'ten video çek (Supabase'e bulaşmadan)
    String? assetPath;
    
    if (_exercise != null) {
      assetPath = _storageService.getExerciseAnimationAssetPath(
        exerciseName: _exercise!.name,
        category: _exercise!.category,
      );
      debugPrint('Video player için asset path: $assetPath');
    }
    
    // Video yoksa placeholder göster
    if (assetPath == null || assetPath.isEmpty) {
      debugPrint('Video path bulunamadı - Egzersiz: ${_exercise?.name}, Kategori: ${_exercise?.category}');
      return Container(
        height: 250,
        width: double.infinity,
        color: cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, 
                color: textGrey.withOpacity(0.5), 
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Video bulunamadı',
                style: TextStyle(color: textGrey),
              ),
              if (_exercise != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_exercise!.name} - ${_exercise!.category}',
                  style: TextStyle(color: textGrey.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_hasVideoError) {
      debugPrint('Video yükleme hatası - Path: $assetPath');
      return Container(
        height: 250,
        width: double.infinity,
        color: cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, 
                color: Colors.red.withOpacity(0.7), 
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Video yüklenemedi',
                style: TextStyle(color: textGrey),
              ),
              const SizedBox(height: 4),
              Text(
                assetPath,
                style: TextStyle(color: textGrey.withOpacity(0.7), fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      // Yüklenme sırasında loading göster
      return Container(
        height: 250,
        width: double.infinity,
        color: cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cyanAccent),
              const SizedBox(height: 16),
              Text(
                'Video yükleniyor...',
                style: TextStyle(color: textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        // Play/Pause butonu - sadece video durduğunda göster
        if (!_videoController!.value.isPlaying)
          GestureDetector(
            onTap: () {
              _videoController!.play();
              setState(() {});
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        // Video üzerine tıklayınca play/pause toggle
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              setState(() {});
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}

