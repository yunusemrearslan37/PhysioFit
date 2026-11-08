import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';
import '../../utils/navigation_helper.dart';
import 'exercise_detail_screen.dart';
import '../../widgets/modern_background.dart';

class ExerciseListScreen extends StatefulWidget {
  final String? initialExerciseId;
  
  const ExerciseListScreen({super.key, this.initialExerciseId});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final _exerciseService = ExerciseService();
  final _storageService = StorageService();

  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  bool _isLoading = true;
  
  // Filtre durumları
  String? _selectedRegion = 'Chest'; // Varsayılan olarak Göğüs seçili
  String? _selectedDifficulty; // null = Tüm Seviyeler

  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _sheetColor = const Color(0xFF121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _textGrey = const Color(0xFFB0B3B8);

  // Bölge kategorileri
  final Map<String, String> _regionMap = {
    'Chest': 'Göğüs',
    'Back': 'Sırt',
    'Shoulders': 'Omuz',
    'Arms': 'Kol',
    'Legs': 'Bacak',
    'Core': 'Karın',
    'Cardio': 'Kardiyovasküler',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Verileri arka planda yükle, kullanıcıyı bekletme
    try {
      final exercises = await _exerciseService.getAllExercises();
      if (mounted) {
        setState(() {
          _allExercises = exercises;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Hata: $e");
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        // Bölge filtresi
        if (_selectedRegion != null) {
          if (exercise.category?.toLowerCase() != _selectedRegion!.toLowerCase()) {
            return false;
          }
        }

        // Zorluk filtresi
        if (_selectedDifficulty != null) {
          if (exercise.difficulty?.toLowerCase() != _selectedDifficulty!.toLowerCase()) {
            return false;
          }
        }

        return true;
      }).toList()
        // Kolaydan zora doğru sırala
        ..sort((a, b) {
          // Zorluk seviyesi sıralama değerleri
          int getDifficultyOrder(String? difficulty) {
            if (difficulty == null) return 99; // Belirtilmemiş en sonda
            switch (difficulty.toLowerCase()) {
              case 'beginner':
                return 1; // En kolay
              case 'intermediate':
                return 2; // Orta
              case 'advanced':
                return 3; // En zor
              default:
                return 99;
            }
          }

          final orderA = getDifficultyOrder(a.difficulty);
          final orderB = getDifficultyOrder(b.difficulty);

          // Önce zorluk seviyesine göre sırala
          if (orderA != orderB) {
            return orderA.compareTo(orderB);
          }

          // Aynı zorluk seviyesindeyse isme göre sırala
          return a.name.compareTo(b.name);
        });
    });
  }

  String _getDifficultyText(String? difficulty) {
    if (difficulty == null) return 'Belirtilmemiş';
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Kolay';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'Zor';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    if (difficulty == null) return Colors.grey;
    switch (difficulty.toLowerCase()) {
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

  String _getCategoryName(String? category) {
    if (category == null) return '';
    return _regionMap[category] ?? category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ModernBackground(
        child: SafeArea(
          child: Column(
          children: [
            // Üst Bar (Geri + Başlık + Filtreler)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
              color: _backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Egzersiz Kütüphanesi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildFilterChips(),
                ],
              ),
            ),

            // Egzersiz Listesi
            Expanded(
              child: _filteredExercises.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: _textGrey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            _isLoading ? 'Yükleniyor...' : 'Egzersiz bulunamadı',
                            style: TextStyle(color: _textGrey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        return _buildExerciseCard(_filteredExercises[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Bölge Filtresi
          _buildFilterChip(
            label: 'Bölge: ${_selectedRegion == null ? 'Tüm Vücut' : _getCategoryName(_selectedRegion)}',
            isSelected: _selectedRegion != null,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: _sheetColor,
                isScrollControlled: true,
                builder: (context) => _buildRegionFilterSheet(),
              );
            },
          ),
          const SizedBox(width: 10),
          // Zorluk Filtresi
          _buildFilterChip(
            label: 'Zorluk: ${_selectedDifficulty == null ? 'Tüm Seviyeler' : _getDifficultyText(_selectedDifficulty)}',
            isSelected: _selectedDifficulty != null,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: _sheetColor,
                isScrollControlled: true,
                builder: (context) => _buildDifficultyFilterSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: _cyanAccent, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _cyanAccent : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRegionFilterSheet() {
    return SafeArea(
      child: Container(
        color: _sheetColor,
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bölge Seçin',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Tüm Vücut', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedRegion = null);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedRegion == null ? Icon(Icons.check, color: _cyanAccent) : null,
                  ),
                  ..._regionMap.entries.map((entry) => ListTile(
                    title: Text(entry.value, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedRegion = entry.key);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedRegion == entry.key ? Icon(Icons.check, color: _cyanAccent) : null,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyFilterSheet() {
    return SafeArea(
      child: Container(
        color: _sheetColor,
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zorluk Seviyesi Seçin',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Tüm Seviyeler', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedDifficulty = null);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedDifficulty == null ? Icon(Icons.check, color: _cyanAccent) : null,
                  ),
                  ListTile(
                    title: const Text('Kolay', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedDifficulty = 'beginner');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedDifficulty == 'beginner' ? Icon(Icons.check, color: _cyanAccent) : null,
                  ),
                  ListTile(
                    title: const Text('Orta', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedDifficulty = 'intermediate');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedDifficulty == 'intermediate' ? Icon(Icons.check, color: _cyanAccent) : null,
                  ),
                  ListTile(
                    title: const Text('Zor', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() => _selectedDifficulty = 'advanced');
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    trailing: _selectedDifficulty == 'advanced' ? Icon(Icons.check, color: _cyanAccent) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseImage(Exercise exercise) {
    // Sadece assets'ten video çek (Supabase'e bulaşmadan)
    final assetPath = _storageService.getExerciseAnimationAssetPath(
      exerciseName: exercise.name,
      category: exercise.category,
    );
    
    debugPrint('Egzersiz: ${exercise.name}, Asset path: $assetPath');
    
    // Asset path yoksa placeholder göster
    if (assetPath == null || assetPath.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: _textGrey.withOpacity(0.5),
          size: 32,
        ),
      );
    }
    
    // Video için thumbnail widget (oynatılmadan)
    // Key ekleyerek her egzersiz için unique widget oluştur
    return _VideoThumbnailWidget(
      assetPath: assetPath,
      width: 120,
      height: 120,
      cardColor: _cardColor,
      cyanAccent: _cyanAccent,
      textGrey: _textGrey,
      key: ValueKey('${exercise.id}_$assetPath'), // Her egzersiz için unique key
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final hideLeftMedia =
        (exercise.category ?? '').trim().toLowerCase() == 'cardio';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          NavigationHelper.createSlideRoute(
            ExerciseDetailScreen(exerciseId: exercise.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol Taraf - Resim/Video
            if (!hideLeftMedia)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: _buildExerciseImage(exercise),
              ),
            // Sağ Taraf - Bilgiler
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Egzersiz Adı
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Zorluk Seviyesi
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: _getDifficultyColor(exercise.difficulty),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getDifficultyText(exercise.difficulty),
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Kategori Etiketi
                    if (exercise.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryName(exercise.category),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Video thumbnail widget - video oynatılmadan sadece ilk frame gösterir
  Widget _VideoThumbnailWidget({
    required String? assetPath,
    required double width,
    required double height,
    required Color cardColor,
    required Color cyanAccent,
    required Color textGrey,
    Key? key,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      child: _VideoThumbnail(
        key: key,
        assetPath: assetPath,
        width: width,
        height: height,
        cardColor: cardColor,
        cyanAccent: cyanAccent,
        textGrey: textGrey,
      ),
    );
  }

}

// Video thumbnail widget - video oynatılmadan sadece ilk frame gösterir
class _VideoThumbnail extends StatefulWidget {
  final String? assetPath;
  final double width;
  final double height;
  final Color cardColor;
  final Color cyanAccent;
  final Color textGrey;

  const _VideoThumbnail({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.cardColor,
    required this.cyanAccent,
    required this.textGrey,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _currentAssetPath;

  @override
  void initState() {
    super.initState();
    _currentAssetPath = widget.assetPath;
    _initializeThumbnail();
  }

  @override
  void didUpdateWidget(_VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Asset path değiştiyse controller'ı yeniden initialize et
    if (oldWidget.assetPath != widget.assetPath) {
      _currentAssetPath = widget.assetPath;
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _initializeThumbnail();
    }
  }

  Future<void> _initializeThumbnail() async {
    try {
      // Sadece assets'ten video yükle
      if (widget.assetPath == null || widget.assetPath!.isEmpty) {
        debugPrint('Video thumbnail: Asset path boş!');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
        return;
      }
      
      final pathToLoad = widget.assetPath;
      if (pathToLoad == null || pathToLoad.isEmpty) {
        return;
      }
      
      debugPrint('Video thumbnail asset path: $pathToLoad');
      _controller = VideoPlayerController.asset(pathToLoad);
      
      await _controller!.initialize();
      
      // Widget güncellenmişse (başka bir video yüklenmişse) dispose et
      if (!mounted || _currentAssetPath != pathToLoad) {
        _controller?.dispose();
        return;
      }
      
      debugPrint('Video thumbnail başarıyla initialize edildi: $pathToLoad');
      
      // Video oynatılmadan sadece ilk frame'i göster
      // Video'yu pause ediyoruz ki oynatılmasın
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero); // İlk frame'e git
      
      if (mounted && _currentAssetPath == pathToLoad) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Video thumbnail yüklenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.cardColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.cardColor,
              widget.cardColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Icon(
          Icons.video_library_outlined,
          color: widget.textGrey.withOpacity(0.5),
          size: 32,
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      // Yüklenme sırasında sadece arka plan göster, loading indicator yok
      if (_hasError) {
        debugPrint('Video thumbnail hata durumunda - Asset: ${widget.assetPath}');
      }
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.cardColor,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
