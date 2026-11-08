import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/strength_record.dart';
import '../../services/strength_tracking_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/modern_background.dart';

class StrengthTrackingScreen extends StatefulWidget {
  const StrengthTrackingScreen({super.key});

  @override
  State<StrengthTrackingScreen> createState() => _StrengthTrackingScreenState();
}

class _StrengthTrackingScreenState extends State<StrengthTrackingScreen> {
  final _strengthService = StrengthTrackingService();
  final _authService = AuthService();
  String? _userId;

  // Seçili egzersiz tipi
  String _selectedExerciseType = 'bench_press';
  final List<String> _exerciseTypes = ['bench_press', 'overhead_press', 'squat', 'deadlift'];

  // Form controllers
  final _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Veriler
  List<StrengthRecord> _records = [];
  bool _isLoading = false;

  // Tasarım Renkleri
  final Color _backgroundColor = const Color(0xFF050914);
  final Color _cardColor = const Color(0x88121A2F);
  final Color _cyanAccent = const Color(0xFF00E5FF);
  final Color _textGrey = const Color(0xFFB0B3B8);

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = _authService.currentUser;
    if (user != null) {
      _userId = user.id;
      // Verileri arka planda yükle
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    if (_userId == null) return;

    // Sadece ilk yüklemede loading göster
    if (_records.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      final records = await _strengthService.getStrengthRecordsByExerciseType(
        userId: _userId!,
        exerciseType: _selectedExerciseType,
      );
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Kayıtlar yüklenirken hata oluştu: $e', Colors.red);
      }
    }
  }

  Future<void> _addRecord() async {
    if (_userId == null) {
      _showSnackBar('Kullanıcı bilgisi bulunamadı.', Colors.red);
      return;
    }

    final weight = double.tryParse(_weightController.text);

    if (weight == null) {
      _showSnackBar('Lütfen ağırlık girin.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _strengthService.addStrengthRecord(
        userId: _userId!,
        exerciseType: _selectedExerciseType,
        weight: weight,
        date: _selectedDate,
      );

      // Formu temizle
      _weightController.clear();
      _selectedDate = DateTime.now();

      await _loadRecords();
      setState(() => _isLoading = false);
      _showSnackBar('PR kaydı başarıyla eklendi!', Colors.green);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Kayıt eklenirken hata oluştu: $e', Colors.red);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getExerciseTypeName(String type) {
    switch (type) {
      case 'bench_press':
        return 'Bench Press';
      case 'overhead_press':
        return 'Overhead Press';
      case 'squat':
        return 'Squat';
      case 'deadlift':
        return 'Deadlift';
      default:
        return type;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Güç Takibi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ModernBackground(
        child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Egzersiz Tipi Seçimi
                  _buildExerciseTypeSelector(),

                  const SizedBox(height: 20),

                  // Grafik
                  if (_isLoading && _records.isEmpty)
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: _cyanAccent),
                      ),
                    )
                  else if (_records.isNotEmpty)
                    _buildChart(),

                  const SizedBox(height: 20),

                  // Yeni Kayıt Formu
                  _buildAddRecordForm(),

                  const SizedBox(height: 20),

                  // Geçmiş Kayıtlar
                  _buildHistoryList(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildExerciseTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _exerciseTypes.map((type) {
          final isSelected = _selectedExerciseType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedExerciseType = type;
                });
                _loadRecords();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _cyanAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getExerciseTypeName(type),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    if (_records.isEmpty) return const SizedBox.shrink();

    // Son 10 kaydı göster - memoize edilmiş
    final recentRecords = _records.length > 10
        ? _records.sublist(_records.length - 10)
        : _records;

    // Spots'u hesapla - sadece gerektiğinde
    final spots = List.generate(recentRecords.length, (index) {
      return FlSpot(index.toDouble(), recentRecords[index].weight);
    });
    final peakWeight = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    var peakIndex = 0;
    for (var i = 0; i < recentRecords.length; i++) {
      if (recentRecords[i].weight != peakWeight) continue;
      if (recentRecords[peakIndex].weight != peakWeight ||
          !recentRecords[i].createdAt.isBefore(recentRecords[peakIndex].createdAt)) {
        peakIndex = i;
      }
    }
    const peakColor = Color(0xFFFFD54F);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getExerciseTypeName(_selectedExerciseType)} - PR İlerlemesi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // Sadece tam sayı değerlerinde ve veri noktalarının olduğu yerlerde tarih göster
                        final intValue = value.toInt();
                        if (value == intValue.toDouble() && 
                            intValue >= 0 && 
                            intValue < recentRecords.length) {
                          final record = recentRecords[intValue];
                          final date = record.date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: _textGrey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                minX: 0,
                maxX: (recentRecords.length - 1).toDouble(),
                minY: spots.isEmpty
                    ? 0
                    : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10,
                maxY: spots.isEmpty
                    ? 100
                    : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _cyanAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isPeak = index == peakIndex;
                        return FlDotCirclePainter(
                          radius: isPeak ? 7 : 4,
                          color: isPeak ? peakColor : _cyanAccent,
                          strokeWidth: 2,
                          strokeColor: isPeak ? const Color(0xFFFFF8E1) : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cyanAccent.withOpacity(0.1),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRecordForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni PR Kaydet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _weightController,
            label: 'PR Ağırlık (kg)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: _cyanAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Tarih: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textGrey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _cyanAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Henüz kayıt bulunmuyor.\nİlk kaydınızı ekleyin!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Geçmiş Kayıtlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._records.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildRecordCard(StrengthRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date.day}/${record.date.month}/${record.date.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatChip('${record.weight} kg PR', _cyanAccent),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteRecord(record.id),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Kaydı Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu kaydı silmek istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _strengthService.deleteStrengthRecord(recordId);
        await _loadRecords();
        _showSnackBar('Kayıt silindi.', Colors.green);
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('Kayıt silinirken hata oluştu: $e', Colors.red);
      }
    }
  }
}

