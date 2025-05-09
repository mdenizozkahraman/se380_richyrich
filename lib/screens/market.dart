import 'package:flutter/material.dart';
import 'package:se380_richyrich/coingecko_service.dart';

class MarketScreen extends StatefulWidget{
  const MarketScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MarketScreenState();
  }

  class _MarketScreenState extends State<MarketScreen>{
  Map<String, double> _prices = {};
  Set<String> _favorites = {};
  bool isLoading = true;

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
      final service = CoinGeckoService();
      try {
        final data = await service.fetchPrices(
          ['bitcoin', 'ethereum', 'tether', 'usd-coin', 'binancecoin',
            'cardano', 'dogecoin', 'solana', 'litecoin'],
          'try',
        );

        print("Gelen veri:");
        print(data);

        setState(() {
          _prices = {
            'BTC/TRY': data['bitcoin']['try'].toDouble(),
            'ETH/TRY': data['ethereum']['try'].toDouble(),
            'USDT/TRY': data['tether']['try'].toDouble(),
            'USDC/TRY': data['usd-coin']['try'].toDouble(),
            'BNB/TRY': data['binancecoin']['try'].toDouble(),
            'ADA/TRY': data['cardano']['try'].toDouble(),
            'DOGE/TRY': data['dogecoin']['try'].toDouble(),
            'SOL/TRY': data['solana']['try'].toDouble(),
            'LTC/TRY': data['litecoin']['try'].toDouble(),

          };
          isLoading = false;
        });
      }
      catch (e){
        print("Error fetching prices: $e");
        setState(()  => isLoading = false);
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              children: _getSortedPrices().map((entry) {
                return _currencyPrice(
                  entry.key,
                  entry.value.toStringAsFixed(2),
                  "Live",
                  true,
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Data provided by CoinGecko',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
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
    return Container(
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
    );

  }

  }

