import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Market'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Market Screen'),
      ),
    );
  }
}