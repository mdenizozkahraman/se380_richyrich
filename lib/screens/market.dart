import 'package:flutter/material.dart';
import 'package:se380_richyrich/coingecko_service.dart';

class MarketScreen extends StatefulWidget{
  const MarketScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MarketScreenState();
  }

  class _MarketScreenState extends State<MarketScreen>{
  Map<String, double> _prices = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPrices();
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
            'BTC/TRY_1': data['bitcoin']['try'].toDouble(),
            'ETH/TRY_1': data['ethereum']['try'].toDouble(),
            'USDT/TRY_1': data['tether']['try'].toDouble(),
            'USDC/TRY_1': data['usd-coin']['try'].toDouble(),
            'BNB/TRY_1': data['binancecoin']['try'].toDouble(),
            'ADA/TRY_1': data['cardano']['try'].toDouble(),
            'DOGE/TRY_1': data['dogecoin']['try'].toDouble(),
            'SOL/TRY_1': data['solana']['try'].toDouble(),
            'LTC/TRY_1': data['litecoin']['try'].toDouble(),

            'BTC/TRY_2': data['bitcoin']['try'].toDouble(),
            'ETH/TRY_2': data['ethereum']['try'].toDouble(),
            'USDT/TRY_2': data['tether']['try'].toDouble(),
            'USDC/TRY_2': data['usd-coin']['try'].toDouble(),
            'BNB/TRY_2': data['binancecoin']['try'].toDouble(),
            'ADA/TRY_2': data['cardano']['try'].toDouble(),
            'DOGE/TRY_2': data['dogecoin']['try'].toDouble(),
            'SOL/TRY_2': data['solana']['try'].toDouble(),
            'LTC/TRY_2': data['litecoin']['try'].toDouble(),

            'BTC/TRY_3': data['bitcoin']['try'].toDouble(),
            'ETH/TRY_3': data['ethereum']['try'].toDouble(),
            'USDT/TRY_3': data['tether']['try'].toDouble(),
            'USDC/TRY_3': data['usd-coin']['try'].toDouble(),
            'BNB/TRY_3': data['binancecoin']['try'].toDouble(),
            'ADA/TRY_3': data['cardano']['try'].toDouble(),
            'DOGE/TRY_3': data['dogecoin']['try'].toDouble(),
            'SOL/TRY_3': data['solana']['try'].toDouble(),
            'LTC/TRY_3': data['litecoin']['try'].toDouble(),

            'BTC/TRY_4': data['bitcoin']['try'].toDouble(),
            'ETH/TRY_4': data['ethereum']['try'].toDouble(),
            'USDT/TRY_4': data['tether']['try'].toDouble(),
            'USDC/TRY_4': data['usd-coin']['try'].toDouble(),
            'BNB/TRY_4': data['binancecoin']['try'].toDouble(),
            'ADA/TRY_4': data['cardano']['try'].toDouble(),
            'DOGE/TRY_4': data['dogecoin']['try'].toDouble(),
            'SOL/TRY_4': data['solana']['try'].toDouble(),
            'LTC/TRY_4': data['litecoin']['try'].toDouble(),
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
              children: _prices.entries.map((entry) {
                return _currencyPrice(
                  entry.key,
                  entry.value.toStringAsFixed(2),
                  "Live",
                  null,
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
          Text(
            pair,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

