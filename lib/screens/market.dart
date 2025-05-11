import 'package:flutter/material.dart';
import 'package:se380_richyrich/cryptocompare_service.dart';
import 'package:se380_richyrich/screens/settings.dart';
import 'package:se380_richyrich/screens/chart_screen.dart';

class MarketScreen extends StatefulWidget{
  const MarketScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MarketScreenState();
  }

  class _MarketScreenState extends State<MarketScreen>{
  Map<String, double> _prices = {};
  Set<String> _favorites = {};
  bool isLoading = true;
  String? errorMessage;

  // CryptoCompare servisini kullan
  final CryptoCompareService _service = CryptoCompareService();

  @override
  void initState() {
    super.initState();
    loadPrices();
  }

  void _toggleFavorite(String pair){
    setState(() {
      if (_favorites.contains(pair)) {
        _favorites.remove(pair);
      }
      else {
        _favorites.add(pair);
      }
    });
  }

  List<MapEntry<String, double>> _getSortedPrices() {
    final entries = _prices.entries.toList();
    entries.sort((a, b) {
      final aIsFavorite = _favorites.contains(a.key);
      final bIsFavorite = _favorites.contains(b.key);
      if (aIsFavorite && !bIsFavorite) return -1;
      if (!aIsFavorite && bIsFavorite) return 1;
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  Future<void> loadPrices() async {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      try {
        // CryptoCompare API'sini kullanarak fiyatları çek
        final data = await _service.fetchPrices(
          ['BTC', 'ETH', 'USDT', 'USDC', 'BNB', 'ADA', 'DOGE', 'SOL', 'LTC'],
          'TRY',
        );

        print("Gelen veri:");
        print(data);

        // Veri kontrolü yap
        if (data.isEmpty) {
          throw Exception('Fiyat verisi alınamadı');
        }

        setState(() {
          // API yanıtını işle ve fiyatları güncelle
          final prices = <String, double>{};
          
          // CryptoCompare API yanıt formatı farklı olduğu için parse etme mantığını güncelle
          void addPrice(String symbol, String displayPair) {
            // CryptoCompare API'sinden gelen formata göre veriyi kontrol et
            if (data.containsKey(symbol) && data[symbol] is Map && data[symbol]['TRY'] != null) {
              // API'den gelen değeri double'a çevir
              final price = data[symbol]['TRY'];
              if (price is num) {
                prices[displayPair] = price.toDouble();
              } else {
                // Eğer sayısal değer değilse, string'den double'a çevirmeyi dene
                try {
                  prices[displayPair] = double.parse(price.toString());
                } catch (e) {
                  // Çevirme başarısız olursa mock değer kullan
                  prices[displayPair] = _getMockPrice(symbol);
                }
              }
            } else {
              // Veri yoksa mock değer kullan
              prices[displayPair] = _getMockPrice(symbol);
            }
          }
          
          // Tüm kripto paraları ekle
          addPrice('BTC', 'BTC/TRY');
          addPrice('ETH', 'ETH/TRY');
          addPrice('USDT', 'USDT/TRY');
          addPrice('USDC', 'USDC/TRY');
          addPrice('BNB', 'BNB/TRY');
          addPrice('ADA', 'ADA/TRY');
          addPrice('DOGE', 'DOGE/TRY');
          addPrice('SOL', 'SOL/TRY');
          addPrice('LTC', 'LTC/TRY');
          
          _prices = prices;
          isLoading = false;
        });
      }
      catch (e){
        print("Error fetching prices: $e");
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
  }
  
  // Mock fiyat değeri döndürme
  double _getMockPrice(String symbol) {
    switch (symbol) {
      case 'BTC':
        return 2000000.0;
      case 'ETH':
        return 120000.0;
      case 'USDT':
      case 'USDC':
        return 30.0;
      case 'BNB':
        return 9000.0;
      case 'ADA':
        return 15.0;
      case 'DOGE':
        return 5.0;
      case 'SOL':
        return 3500.0;
      case 'LTC':
        return 2500.0;
      default:
        return 100.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Market',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: loadPrices,
                  child: ListView(
                    children: [
                      ..._getSortedPrices().map((entry) {
                        return _currencyPrice(
                          entry.key,
                          entry.value.toStringAsFixed(2),
                          "Live",
                          true,
                        );
                      }).toList(),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Data provided by CryptoCompare',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
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
          Text(
            'Veri yüklenemedi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage?.replaceAll('Exception: ', '') ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loadPrices,
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

  Widget _currencyPrice(String pair, String price, String change, bool? isPositive) {
    Color changeColor;
    if (isPositive == null) {
      changeColor = Colors.grey;
    } else {
      changeColor = isPositive ? Colors.green: Colors.red;
    }

    // CryptoCompare API için sembolleri eşleştirme
    final Map<String, String> coinIds = {
      'BTC/TRY': 'BTC',
      'ETH/TRY': 'ETH',
      'USDT/TRY': 'USDT',
      'USDC/TRY': 'USDC',
      'BNB/TRY': 'BNB',
      'ADA/TRY': 'ADA',
      'DOGE/TRY': 'DOGE',
      'SOL/TRY': 'SOL',
      'LTC/TRY': 'LTC',
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChartScreen(
              coinId: coinIds[pair]!,
              pair: pair,
              currentPrice: price,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleFavorite(pair),
                  child: Icon(
                    _favorites.contains(pair) ? Icons.star : Icons.star_border,
                    color: _favorites.contains(pair) ? Colors.amber : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  pair,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              change,
              style: TextStyle(fontSize: 14, color: changeColor),
            ),
          ],
        ),
      ),
    );
  }

  }

