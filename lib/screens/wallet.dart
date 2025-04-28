import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {

  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WalletScreenState();
  
}

class _WalletScreenState extends State<WalletScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Total Balance",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '\$0,00',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),

          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Empty for now
              itemBuilder: (context, index) {
                return const ListTile(
                  title: Text('Stock'),
                  subtitle: Text('Amount: 0'),
                  trailing: Text('\$0.00'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}