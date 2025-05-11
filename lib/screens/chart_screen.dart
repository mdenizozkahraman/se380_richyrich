import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:se380_richyrich/cryptocompare_service.dart';

class ChartScreen extends StatefulWidget {
  final String coinId;
  final String pair;
  final String currentPrice;

  const ChartScreen({
    super.key,
    required this.coinId,
    required this.pair,
    required this.currentPrice,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<Map<String, dynamic>> _chartData = [];
  bool _isLoading = true;
  int _selectedDays = 7;
  String? _errorMessage;
  
  // CryptoCompare servisini kullan
  final CryptoCompareService _service = CryptoCompareService();

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // CryptoCompare API'sini kullanarak grafik verilerini çek
      final data = await _service.fetchMarketChart(widget.coinId, 'TRY', _selectedDays);
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chart data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  double _getMinPrice() {
    if (_chartData.isEmpty) return 0;
    return _chartData.map((e) => e['price'] as double).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    if (_chartData.isEmpty) return 0;
    return _chartData.map((e) => e['price'] as double).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pair),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[900]!, Colors.blue[800]!],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeButton(1, '1G'),
                          _buildTimeButton(7, '7G'),
                          _buildTimeButton(30, '30G'),
                          _buildTimeButton(90, '90G'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _chartData.isEmpty
                            ? const Center(child: Text('Veri bulunamadı'))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: (_getMaxPrice() - _getMinPrice()) / 5,
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: (_getMaxPrice() - _getMinPrice()) / 5,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            value.toStringAsFixed(0),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: _chartData.length / 5,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >= 0 && value.toInt() < _chartData.length) {
                                            final date = DateTime.fromMillisecondsSinceEpoch(
                                              _chartData[value.toInt()]['timestamp'].toInt()
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                '${date.day}/${date.month}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  minX: 0,
                                  maxX: _chartData.length.toDouble() - 1,
                                  minY: _getMinPrice() * 0.99,
                                  maxY: _getMaxPrice() * 1.01,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _chartData.asMap().entries.map((entry) {
                                        return FlSpot(
                                          entry.key.toDouble(),
                                          entry.value['price'].toDouble(),
                                        );
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Güncel Fiyat: ${widget.currentPrice} TRY',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Data provided by CryptoCompare',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Grafik verisi yüklenemedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage?.replaceAll('Exception: ', '') ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadChartData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(int days, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedDays = days);
        _loadChartData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedDays == days ? Colors.blue : Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }
}