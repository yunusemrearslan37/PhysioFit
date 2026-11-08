import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import '../../utils/navigation_helper.dart';
import '../exercises/exercise_detail_screen.dart';
import '../../widgets/modern_background.dart';

class EquipmentRecognitionScreen extends StatefulWidget {
  const EquipmentRecognitionScreen({super.key});

  @override
  State<EquipmentRecognitionScreen> createState() => _EquipmentRecognitionScreenState();
}

class _EquipmentRecognitionScreenState extends State<EquipmentRecognitionScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF050914);
  static const _card = Color(0x88121A2F);
  static const _cyan = Color(0xFF00E5FF);

  static const _modelAssetPath = 'assets/models/best_integer_quant.tflite';
  static const _labelsAssetPath = 'assets/models/labels.txt';

  // Netron: input float32[1,640,640,3] output float32[1,17,8400]
  static const int _inputSize = 640;
  static const int _numCandidates = 8400;

  final _exerciseService = ExerciseService();

  CameraController? _camera;
  Interpreter? _interpreter;
  List<String> _labels = const [];

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _scanOverlayVisible = false;
  String? _lastDetectedLabel;
  Exercise? _matchedExercise;
  String? _resultNote;

  late AnimationController _scanAnimation;

  // Model label -> mevcut egzersiz adı (DB'de var olan "name")
  // Not: olmayanlar şimdilik null kalır, uyarı gösterilir.
  final Map<String, String?> _labelToExerciseName = const {
    'chest press machine': 'Chest Press Machine',
    'lat pull down': 'Lat Pulldown',
    'seated cable rows': 'Cable Row',
    'arm curl machine': 'Arm Curl Machine',
    'chest fly machine': 'Dumbbell Flyes',
    'chinning dipping': 'Weighted Dips',
    'lateral raises machine': 'Lateral Raise Machine',
    'leg extension': 'Leg Extension',
    'leg press': 'Leg Press',
    // labels.txt içinde "reg curl machine" yazıyor; onu da destekleyelim
    'reg curl machine': 'Leg Curl Machine',
    // olası doğru yazım
    'leg curl machine': 'Leg Curl Machine',
    'seated dip machine': 'Weighted Dips',
    'shoulder press machine': 'Overhead Press',
    'smith machine': 'Smith Machine',
  };

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    unawaited(_init());
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
    _camera?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final labelsStr = await rootBundle.loadString(_labelsAssetPath);
      final labels = labelsStr
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final camController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await camController.initialize();

      final options = InterpreterOptions()..threads = 2;
      final interpreter = await Interpreter.fromAsset(_modelAssetPath, options: options);
      interpreter.allocateTensors();

      // Debug: model tensor bilgisi (logcat/console)
      try {
        final inTensor = interpreter.getInputTensor(0);
        final outTensor = interpreter.getOutputTensor(0);
        debugPrint('TFLite input: shape=${inTensor.shape} type=${inTensor.type}');
        debugPrint('TFLite output: shape=${outTensor.shape} type=${outTensor.type}');
      } catch (_) {
        // ignore
      }

      if (!mounted) return;
      setState(() {
        _labels = labels;
        _camera = camController;
        _interpreter = interpreter;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitializing = false);
      _showSnack('Başlatma hatası: $e', isError: true);
    }
  }

  Future<(String?, double?)> _runInference(
    Uint8List jpegBytes,
    Interpreter interpreter,
  ) async {
    final input = _buildInputTensor(jpegBytes);
    final output = Float32List(17 * _numCandidates);
    interpreter.run(input.buffer, output.buffer);
    return _pickBestLabel(output);
  }

  Future<void> _captureAndRecognize() async {
    final cam = _camera;
    final interpreter = _interpreter;
    if (cam == null || interpreter == null) {
      _showSnack('Kamera veya model hazır değil.', isError: true);
      return;
    }
    if (_isProcessing) return;
    if (!cam.value.isInitialized) {
      _showSnack('Kamera henüz hazır değil. Lütfen tekrar deneyin.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _matchedExercise = null;
      _resultNote = null;
    });

    try {
      final xfile = await cam.takePicture();
      final bytes = await File(xfile.path).readAsBytes();

      if (!mounted) return;

      _scanAnimation.reset();
      _scanAnimation.repeat();
      setState(() => _scanOverlayVisible = true);

      final inferenceFuture = _runInference(bytes, interpreter);
      await Future.wait<void>([
        inferenceFuture.then<void>((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 1650)),
      ]);

      final (label, score) = await inferenceFuture;

      _scanAnimation.stop();
      _scanAnimation.reset();

      if (!mounted) return;
      setState(() {
        _scanOverlayVisible = false;
        _lastDetectedLabel = label;
      });

      if (label == null || score == null) {
        setState(() {
          _matchedExercise = null;
          _resultNote = 'Ekipman net görünmedi. Bir kez daha tara.';
        });
        return;
      }

      await _resolveMatchedExercise(label);
    } catch (e, st) {
      _scanAnimation.stop();
      _scanAnimation.reset();
      if (mounted) setState(() => _scanOverlayVisible = false);

      debugPrint('EquipmentRecognition error: $e');
      debugPrintStack(stackTrace: st);
      final msg = e.toString().contains('failed precondition')
          ? 'Model çalıştırılamadı (failed precondition). Bu genelde input formatı/runtime uyumsuzluğundan olur.'
          : 'Tarama hatası: $e';
      _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  /// Input: float32[1,640,640,3]
  /// Not: model graph'ında Quantize olduğu için 0..255 float vermek genelde uyumludur.
  Float32List _buildInputTensor(Uint8List jpegBytes) {
    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      throw Exception('Görsel decode edilemedi');
    }

    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);
    final input = Float32List(1 * _inputSize * _inputSize * 3);

    var i = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final p = resized.getPixel(x, y);
        // YOLO export preprocessing: genelde 0..1 aralığı
        input[i++] = p.r.toDouble() / 255.0;
        input[i++] = p.g.toDouble() / 255.0;
        input[i++] = p.b.toDouble() / 255.0;
      }
    }
    return input;
  }

  (String? label, double? score) _pickBestLabel(Float32List output) {
    if (_labels.isEmpty) return (null, null);

    final int numClasses = _labels.length; // 13
    if (4 + numClasses != 17) {
      // Beklenen format değilse yanlış decode etmeyelim.
      return (null, null);
    }

    double bestScore = -1;
    int bestClass = -1;

    // output layout: [1, 17, 8400] flattened
    // index(channel, candidate) = channel * 8400 + candidate
    for (int j = 0; j < _numCandidates; j++) {
      for (int c = 0; c < numClasses; c++) {
        final score = output[(4 + c) * _numCandidates + j];
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }
    }

    // Eşik: çok düşükse "tespit edilemedi"
    if (bestClass < 0 || bestScore < 0.35) {
      return (null, null);
    }

    return (_labels[bestClass], bestScore);
  }

  Future<void> _resolveMatchedExercise(String detectedLabel) async {
    final targetExerciseName = _labelToExerciseName[detectedLabel.trim().toLowerCase()];
    if (targetExerciseName == null || targetExerciseName.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _matchedExercise = null;
        _resultNote = 'Bu alet için hareket henüz yok.';
      });
      return;
    }

    try {
      final all = await _exerciseService.getAllExercises(includeHidden: true);
      Exercise? match;
      final targetNorm = targetExerciseName.trim().toLowerCase();
      for (final exercise in all) {
        if (exercise.name.trim().toLowerCase() == targetNorm) {
          match = exercise;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _matchedExercise = match;
        _resultNote = match == null ? 'Bu alet için hareket henüz yok.' : null;
      });
    } catch (e) {
      _showSnack('Hareket eşleştirilemedi: $e', isError: true);
    }
  }

  void _openMatchedExercise() {
    final match = _matchedExercise;
    if (match == null) return;
    Navigator.of(context).push(
      NavigationHelper.createSlideRoute(
        ExerciseDetailScreen(exerciseId: match.id),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFB00020) : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Köşe "viewfinder" — ince cyan çerçeve.
  Widget _viewfinderCorners() {
    const len = 28.0;
    const inset = 18.0;
    BorderSide bs(Color c) => BorderSide(color: c, width: 2.5);

    Widget corner(Alignment inner) {
      final top = inner.y < 0 ? inset : null;
      final bottom = inner.y > 0 ? inset : null;
      final left = inner.x < 0 ? inset : null;
      final right = inner.x > 0 ? inset : null;
      return Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: SizedBox(
          width: len,
          height: len,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: inner.y < 0 ? bs(_cyan.withValues(alpha: 0.65)) : BorderSide.none,
                bottom: inner.y > 0 ? bs(_cyan.withValues(alpha: 0.65)) : BorderSide.none,
                left: inner.x < 0 ? bs(_cyan.withValues(alpha: 0.65)) : BorderSide.none,
                right: inner.x > 0 ? bs(_cyan.withValues(alpha: 0.65)) : BorderSide.none,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        corner(Alignment.topLeft),
        corner(Alignment.topRight),
        corner(Alignment.bottomLeft),
        corner(Alignment.bottomRight),
      ],
    );
  }

  Widget _buildResultChip() {
    final label = _lastDetectedLabel;
    if (label == null && _resultNote == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Row(
          children: [
            Icon(Icons.photo_camera_outlined, color: Colors.white38, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarama bekleniyor',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ekipmana odaklan ve tara düğmesine dokun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final match = _matchedExercise;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tanınan alet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label ?? 'Tanınamadı',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            match == null ? (_resultNote ?? 'Bu alet için hareket henüz yok.') : match.name,
            style: TextStyle(
              color: match == null ? const Color(0xFFFFD54F) : Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (match != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _openMatchedExercise,
                style: TextButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _bg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Harekete git', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final loading = _isProcessing;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading
          ? null
          : () {
              unawaited(_captureAndRecognize());
            },
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: loading
                ? [_cyan.withValues(alpha: 0.35), _cyan.withValues(alpha: 0.2)]
                : [_cyan.withValues(alpha: 0.95), const Color(0xFF00B8D9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              )
            else
              Icon(Icons.center_focus_strong_rounded,
                  color: _bg.withValues(alpha: 0.95), size: 24),
            const SizedBox(width: 10),
            Text(
              loading ? 'Görüntü işleniyor…' : 'Fotoğraf çek ve tara',
              style: TextStyle(
                color: _bg.withValues(alpha: 0.95),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(bool showSubtitle) {
    return AppBar(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ekipman tanıma',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          if (showSubtitle)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Makinenin tamamını kadraja al • net çekim',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(false),
        body: ModernBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _cyan.withValues(alpha: 0.1),
                        border: Border.all(color: _cyan.withValues(alpha: 0.22)),
                      ),
                      child:
                          Icon(Icons.hdr_enhanced_select_rounded, size: 44, color: _cyan.withValues(alpha: 0.95)),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Kamera ve model hazırlanıyor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3, color: _cyan.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: _appBar(false),
        body: ModernBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off_rounded,
                            size: 48, color: Colors.redAccent.withValues(alpha: 0.85)),
                        const SizedBox(height: 18),
                        const Text(
                          'Kamera açılamadı',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İzinleri kontrol edin veya cihazı yeniden başlatın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(true),
      body: ModernBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(cam),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.42),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(child: _viewfinderCorners()),
                        if (_scanOverlayVisible) _scanningOverlay(),
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _cyan.withValues(alpha: 0.15)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded, color: _cyan, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Ekipman net görünsün; flaşı açık ortamda dene.',
                                      style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 4, 16, 14 + MediaQuery.paddingOf(context).bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bg,
                      Color.lerp(_bg, const Color(0xFF0A1020), 0.5)!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    _buildResultChip(),
                    const SizedBox(height: 16),
                    _buildScanButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanningOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.58),
                ),
                CustomPaint(
                  painter: _ScanBeamPainter(
                    progress: _scanAnimation.value,
                    beamColor: _cyan,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 44),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: _card.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _cyan.withValues(alpha: 0.28)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radar_rounded, color: _cyan.withValues(alpha: 0.92), size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Taranıyor…',
                            style: TextStyle(
                              color: Colors.grey.shade200,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Yukarıdan aşağı süzülen tarama şeridi.
class _ScanBeamPainter extends CustomPainter {
  _ScanBeamPainter({
    required this.progress,
    required this.beamColor,
  });

  final double progress;
  final Color beamColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * progress.clamp(0.0, 1.0);
    final band = size.height * 0.055;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, cy),
      width: size.width + 40,
      height: band + 36,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          beamColor.withValues(alpha: 0.0),
          beamColor.withValues(alpha: 0.55),
          beamColor.withValues(alpha: 0.92),
          beamColor.withValues(alpha: 0.52),
          Colors.transparent,
        ],
        stops: const [0.0, 0.38, 0.48, 0.53, 0.62, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.drawRect(Rect.fromLTWH(-20, cy - band, size.width + 40, band * 3), paint);
    canvas.restore();

    final linePaint = Paint()
      ..color = beamColor.withValues(alpha: 0.92)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(-8, cy), Offset(size.width + 8, cy), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanBeamPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.beamColor != beamColor;
}
