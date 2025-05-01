import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class Asset{
  final String currency;
  final double amount;
  final double averagePrice;

  Asset({
    required this.currency,
    required this.amount,
    required this.averagePrice
  });

  double get totalValue => amount * averagePrice;
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  final List<Asset> _assets = [];

  void _showAddAssetDialog(BuildContext context, String currency){
    final TextEditingController amountController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Add $currency"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  hintText: "Enter amount"
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                    labelText: "Average Purchase Price",
                    hintText: "Enter average price"
              ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    setState(() {
                      final newAmount = double.parse(amountController.text);
                      final newPrice = double.parse(priceController.text);
                      final existingAssetIndex = _assets.indexWhere( (asset) => asset.currency == currency);

                      if (existingAssetIndex != -1){
                        final existingAsset = _assets[existingAssetIndex];
                        final totalAmount = existingAsset.amount + newAmount;
                        final weightedAveragePrice = ((existingAsset.amount * existingAsset.averagePrice) + (newAmount * newPrice)) / totalAmount;

                        _assets[existingAssetIndex] = Asset(
                            currency: currency,
                            amount: totalAmount,
                            averagePrice: weightedAveragePrice
                        );
                      }
                      else{
                        _assets.add(Asset(
                            currency: currency,
                            amount: newAmount,
                            averagePrice: newPrice)
                        );
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text("Add",
                style: TextStyle(color: Colors.blue[500]),)
            ),
          ],
        ),
    );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Wallet",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[900]!, Colors.blue[900]!],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Total Balance",
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_assets.fold(0.0, (sum, asset) => sum + asset.totalValue).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 40,
                        title: '40%',
                        color: Colors.blue[400],
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: 30,
                        title: '30%',
                        color: Colors.green[400],
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: 30,
                        title: '30%',
                        color: Colors.orange[400],
                        radius: 100,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assets',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                PopupMenuButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  onSelected: (value) => _showAddAssetDialog(context, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "USD",
                      child: Text("USD"),
                    ),
                    const PopupMenuItem(
                      value: "EUR",
                      child: Text("EUR"),
                    ),
                    const PopupMenuItem(
                      value: "XAU",
                      child: Text("XAU"),
                    ),
                    const PopupMenuItem(
                      value: "BTC",
                      child: Text("BTC"),
                    ),
                  ] ,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final asset = _assets[index];
                return Dismissible(
                  key: Key(asset.currency + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Asset"),
                        content: Text("Are you sure you want to delete ${asset.currency}?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      _assets.removeAt(index);
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        asset.currency,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount: ${asset.amount}'),
                          Text('Average Price: \$${asset.averagePrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Text(
                        '\$${asset.totalValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



