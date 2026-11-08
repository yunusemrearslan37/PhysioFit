import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // FontFeature için
import '../../widgets/modern_background.dart';

class TimerStopwatchScreen extends StatefulWidget {
  const TimerStopwatchScreen({super.key});

  @override
  State<TimerStopwatchScreen> createState() => _TimerStopwatchScreenState();
}

class _TimerStopwatchScreenState extends State<TimerStopwatchScreen> with TickerProviderStateMixin {
  // --- Renkler ve Tasarım Sabitleri ---
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _inactiveColor = const Color(0xFF2C3550);

  // --- Durum Değişkenleri ---
  int _selectedMode = 0; // 0: Kronometre, 1: Zamanlayıcı
  late TabController _tabController;
  late AnimationController _rotationController;

  // --- Kronometre Değişkenleri ---
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _stopwatchDisplay = '00:00.00';
  List<String> _laps = []; // Tur listesi

  // --- Zamanlayıcı Değişkenleri ---
  int _selectedHour = 0;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  
  Timer? _countdownTimer;
  int _totalSeconds = 0;
  int _initialTimerSeconds = 0; // Başlangıç süresi (ilerleme hesaplaması için)
  bool _isTimerRunning = false;
  double _timerProgress = 1.0; // Daire animasyonu için

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedMode = _tabController.index;
      });
    });
    // Dönen halka için animasyon controller (daha yavaş dönüş için 8 saniye)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // --- KRONOMETRE MANTIKLARI ---
  void _startStopwatch() {
    _stopwatch.start();
    _rotationController.repeat(); // Dönen halka animasyonunu başlat
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _stopwatchDisplay = _formatStopwatchTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
    _rotationController.stop(); // Dönen halka animasyonunu durdur
    setState(() {});
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _stopwatchTimer?.cancel();
    _rotationController.reset(); // Dönen halka animasyonunu sıfırla
    setState(() {
      _stopwatchDisplay = '00:00.00';
      _laps.clear();
    });
  }

  void _lapStopwatch() {
    setState(() {
      _laps.insert(0, _stopwatchDisplay);
    });
  }

  String _formatStopwatchTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr.$hundredsStr";
  }

  // --- ZAMANLAYICI MANTIKLARI ---
  void _startTimer() {
    if (_totalSeconds == 0) {
      // Tekerleklerden veriyi al
      _totalSeconds = (_selectedHour * 3600) + (_selectedMinute * 60) + _selectedSecond;
      _initialTimerSeconds = _totalSeconds; // Başlangıç süresini kaydet
    }
    
    if (_totalSeconds <= 0) return;

    setState(() => _isTimerRunning = true);
    
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_totalSeconds > 0) {
          _totalSeconds--;
          // İlerleme yüzdesini hesapla
          if (_initialTimerSeconds > 0) {
            _timerProgress = _totalSeconds / _initialTimerSeconds;
          }
        } else {
          _isTimerRunning = false;
          _timerProgress = 0.0;
          timer.cancel();
          _showTimerCompleted();
        }
      });
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _totalSeconds = 0;
      _initialTimerSeconds = 0;
      _timerProgress = 1.0;
    });
  }

  void _showTimerCompleted() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Süre Doldu!"),
        backgroundColor: _cyanAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimerTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // --- ARAYÜZ (BUILD) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ModernBackground(
        child: SafeArea(
          child: Column(
          children: [
            const SizedBox(height: 20),
            // Başlık
            const Text(
              "Zaman",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 1. ÖZEL TAB YAPISI (Görseldeki gibi)
            _buildCustomToggle(),

            const SizedBox(height: 30),

            // İçerik Alanı
            Expanded(
              child: IndexedStack(
                index: _selectedMode,
                children: [
                  _buildStopwatchView(), // 0: Kronometre
                  _buildTimerView(),     // 1: Zamanlayıcı
                ],
              ),
            ),

            // Alt Kontrol Butonları (Başlat / Sıfırla)
            _buildBottomControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  // --- WIDGET PARÇALARI ---

  Widget _buildCustomToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 50,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Hareketli Arka Plan (Glow Effect)
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.decelerate,
            alignment: _selectedMode == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cyanAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _cyanAccent.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
            ),
          ),
          // Metinler
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMode = 0),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Kronometre",
                      style: TextStyle(
                        color: _selectedMode == 0 ? _backgroundColor : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMode = 1),
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: Text(
                      "Zamanlayıcı",
                      style: TextStyle(
                        color: _selectedMode == 1 ? _backgroundColor : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- KRONOMETRE GÖRÜNÜMÜ ---
  Widget _buildStopwatchView() {
    return Column(
      children: [
        // Daire ve Süre
        SizedBox(
          height: 280,
          width: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan halkası
              CircularProgressIndicator(
                value: 1.0,
                color: _cardColor,
                strokeWidth: 8,
              ),
              // Dönen halka (Sadece çalışırken) - Yavaş dönüş animasyonu
              if (_stopwatch.isRunning)
                RotationTransition(
                  turns: _rotationController,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    color: _cyanAccent,
                    strokeWidth: 8,
                  ),
                ),
              // Ortadaki Yazı
              Center(
                child: Text(
                  _stopwatchDisplay,
                  style: TextStyle(
                    color: _cyanAccent,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(color: _cyanAccent.withOpacity(0.5), blurRadius: 20)
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Tur Listesi (Görseldeki "Tur 1", "Tur 2")
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            itemCount: _laps.length,
            itemBuilder: (context, index) {
              final lapTime = _laps[index];
              final lapIndex = _laps.length - index;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: _cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tur $lapIndex", style: const TextStyle(color: Colors.grey)),
                    Text(lapTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- ZAMANLAYICI GÖRÜNÜMÜ (Tekerlekli) ---
  Widget _buildTimerView() {
    // Eğer zamanlayıcı çalışıyorsa, Kronometre gibi dairesel geri sayım göster
    if (_isTimerRunning || (_totalSeconds > 0 && _totalSeconds < ((_selectedHour * 3600) + (_selectedMinute * 60) + _selectedSecond))) {
      return Center(
        child: SizedBox(
          height: 280,
          width: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka plan halkası
              CircularProgressIndicator(
                value: 1.0,
                color: _cardColor,
                strokeWidth: 8,
              ),
              // İlerleme halkası
              CircularProgressIndicator(
                value: _timerProgress,
                color: _cyanAccent,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
              // Ortadaki zaman
              Center(
                child: Text(
                  _formatTimerTime(_totalSeconds),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: _cyanAccent.withOpacity(0.5), blurRadius: 20)]
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Çalışmıyorsa, TEKERLEK SEÇİCİLERİ göster (Görseldeki arka plan gibi)
    return Center(
      child: SizedBox(
        height: 250,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWheelPicker(23, (val) => _selectedHour = val, "Saat"),
            _buildColon(),
            _buildWheelPicker(59, (val) => _selectedMinute = val, "Dakika"),
            _buildColon(),
            _buildWheelPicker(59, (val) => _selectedSecond = val, "Saniye"),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelPicker(int maxValue, Function(int) onChanged, String label) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: _cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          width: 70,
          height: 200,
          child: CupertinoPicker(
            itemExtent: 50,
            selectionOverlay: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: _cyanAccent.withOpacity(0.3))),
              ),
            ),
            onSelectedItemChanged: onChanged,
            children: List.generate(maxValue + 1, (index) => Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 30),
      child: Text(":", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 30)),
    );
  }

  // --- ALT KONTROL BUTONLARI ---
  Widget _buildBottomControls() {
    bool isRunning = _selectedMode == 0 ? _stopwatch.isRunning : _isTimerRunning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sol Buton (Sıfırla veya Tur)
          GestureDetector(
            onTap: () {
              if (_selectedMode == 0) {
                 // Kronometre modunda çalışıyorsa Tur at, duruyorsa Sıfırla
                 if (_stopwatch.isRunning) _lapStopwatch(); else _resetStopwatch();
              } else {
                _resetTimer();
              }
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _cyanAccent, width: 2),
              ),
              child: Icon(
                _selectedMode == 0 && _stopwatch.isRunning ? Icons.flag : Icons.refresh,
                color: _cyanAccent,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Sağ Buton (Başlat / Durdur) - Büyük Neon Buton
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedMode == 0) {
                  if (_stopwatch.isRunning) _stopStopwatch(); else _startStopwatch();
                } else {
                  if (_isTimerRunning) _pauseTimer(); else _startTimer();
                }
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: isRunning ? Colors.redAccent : _cyanAccent, // Durdur kırmızı, Başlat mavi
                  boxShadow: [
                    BoxShadow(
                      color: (isRunning ? Colors.redAccent : _cyanAccent).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    isRunning ? "Durdur" : "Başlat",
                    style: TextStyle(
                      color: isRunning ? Colors.white : _backgroundColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}