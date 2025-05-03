import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

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
              colors: [
                Colors.blue[900]!,
                Colors.blue[800]!,
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          _currencyPrice("USD/TRY", "38,57", "0,38%", true),
          _currencyPrice("EUR/TRY", "43,64", "0,38%", false),
          _currencyPrice("XAU/TRY", "4.094,15", "0,38%", null),
          _currencyPrice("BTC/TRY", "3.744.397,87", "0,38%", true),
          _currencyPrice("USD/TRY", "38,57", "0,38%", true),
          _currencyPrice("EUR/TRY", "43,64", "0,38%", false),
          _currencyPrice("XAU/TRY", "4.094,15", "0,38%", null),
          _currencyPrice("BTC/TRY", "3.744.397,87", "0,38%", true),
          _currencyPrice("USD/TRY", "38,57", "0,38%", true),
          _currencyPrice("EUR/TRY", "43,64", "0,38%", false),
          _currencyPrice("XAU/TRY", "4.094,15", "0,38%", null),
          _currencyPrice("BTC/TRY", "3.744.397,87", "0,38%", true),
          _currencyPrice("USD/TRY", "38,57", "0,38%", true),
          _currencyPrice("EUR/TRY", "43,64", "0,38%", false),
          _currencyPrice("XAU/TRY", "4.094,15", "0,38%", null),
          _currencyPrice("BTC/TRY", "3.744.397,87", "0,38%", true),

        ],
      )
    );
  }

  Widget _currencyPrice(String pair, String price, String change, bool? isPositive){
    Color changeColor;
    if (isPositive == null){
      changeColor = Colors.grey;
    }
    else{
      changeColor = isPositive ? Colors.green : Colors.red;
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

          ),
          Text(
            change,
            style: TextStyle(
              fontSize: 14,
              color: changeColor,
            ),
          ),
        ],
      ),
    );

  }
}