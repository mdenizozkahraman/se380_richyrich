import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:se380_richyrich/coingecko_service.dart';


class Asset{
  final String currency;
  final double amount;
  final double averagePrice;
  double? realPrice;

  Asset({
    required this.currency,
    required this.amount,
    required this.averagePrice,
    this.realPrice,
  });

  double get totalValue => amount * (realPrice ?? 0);
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  final List<Asset> _assets = [];
  Timer? _priceUpdateTimer;

  Future<void> _updateRealPrices() async {
    final service = CoinGeckoService();
    try {
      final data = await service.fetchPrices(
        ['bitcoin', 'ethereum', 'tether', 'usd-coin', 'binancecoin',
          'cardano', 'dogecoin', 'solana', 'litecoin'],
        'try',
      );

      setState(() {
        for (var asset in _assets) {
          switch (asset.currency) {
            case "BTC":
              asset.realPrice = data['bitcoin']['try'].toDouble();
              break;
            case "ETH":
              asset.realPrice = data['ethereum']['try'].toDouble();
              break;
            case "USDT":
              asset.realPrice = data['tether']['try'].toDouble();
              break;
            case "USDC":
              asset.realPrice = data['usd-coin']['try'].toDouble();
              break;
            case "BNB":
              asset.realPrice = data['binancecoin']['try'].toDouble();
              break;
            case "ADA":
              asset.realPrice = data['cardano']['try'].toDouble();
              break;
            case "DOGE":
              asset.realPrice = data['dogecoin']['try'].toDouble();
              break;
            case "SOL":
              asset.realPrice = data['solana']['try'].toDouble();
              break;
            case "LTC":
              asset.realPrice = data['litecoin']['try'].toDouble();
              break;
          }
        }
      });
    } catch (e) {
      print("Error fetching prices: $e");
    }
  }
  
  @override
  void initState(){
    super.initState();
    _updateRealPrices();
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateRealPrices();
  });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  Color _getColorForCurrency(String currency){
    switch (currency){
      case "BTC":
        return Colors.orange;
      case "ETH":
        return Colors.blue;
      case "USDT":
        return Colors.green;
      case "USDC":
        return Colors.blue[300]!;
      case "BNB":
        return Colors.yellow[700]!;
      case "ADA":
        return Colors.blue[900]!;
      case "DOGE":
        return Colors.amber;
      case "SOL":
        return Colors.purple;
      case "LTC":
        return Colors.grey[400]!;
      default:
        return Colors.grey;
    }
  }

  Color _getContrastColor(Color color) {
    final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

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
                            averagePrice: weightedAveragePrice,
                            realPrice: 0
                        );
                      }
                      else{
                        _assets.add(Asset(
                            currency: currency,
                            amount: newAmount,
                            averagePrice: newPrice,
                            realPrice: 0)
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

  void _showEditAssetDialog(BuildContext context, Asset asset, int index){
    final TextEditingController amountController = TextEditingController(text: asset.amount.toString());
    final TextEditingController priceController = TextEditingController(text: asset.averagePrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${asset.currency}"),
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          TextButton(
              onPressed: () {
                if (amountController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  setState(() {
                    _assets[index] = Asset(
                      currency: asset.currency,
                      amount: double.parse(amountController.text),
                      averagePrice: double.parse(priceController.text),
                      realPrice: asset.realPrice
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.blue[500]),
              )
          ),
        ],
      ),
    );
  }

  void _showSellAssetDialog(BuildContext context, String currency) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sell $currency"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                  labelText: "Amount",
                  hintText: "Enter amount to sell"
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                  labelText: "Sell Price",
                  hintText: "Enter sell price"
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
                  final existingAssetIndex = _assets.indexWhere((asset) => asset.currency == currency);

                  if (existingAssetIndex != -1) {
                    final existingAsset = _assets[existingAssetIndex];
                    if (existingAsset.amount >= newAmount) {
                      final remainingAmount = existingAsset.amount - newAmount;
                      if (remainingAmount > 0) {
                        _assets[existingAssetIndex] = Asset(
                            currency: currency,
                            amount: remainingAmount,
                            averagePrice: existingAsset.averagePrice,
                            realPrice: existingAsset.realPrice
                        );
                      } else {
                        _assets.removeAt(existingAssetIndex);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You don\'t have enough $currency to sell'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              "Sell",
              style: TextStyle(color: Colors.red[500]),
            ),
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
                    sections: _assets.isEmpty ? [
                      PieChartSectionData(
                        value: 100,
                        title: '100%',
                        color: Colors.grey[400],
                        radius: 100,
                        titleStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] : _assets.map((asset) {
                      final totalValue = _assets.fold(0.0, (sum, a) => sum + a.totalValue);
                      final percentage = (asset.totalValue / totalValue) * 100;
                      final color = _getColorForCurrency(asset.currency);
                      return PieChartSectionData(
                        value: percentage,
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: _getColorForCurrency(asset.currency),
                        radius: 100,
                        titleStyle: TextStyle(
                        color: _getContrastColor(color),
                        fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
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
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Select Cryptocurrency"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text("Bitcoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "BTC");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Ethereum"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "ETH");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Tether"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "USDT");
                                  },
                                ),
                                ListTile(
                                  title: const Text("USD Coin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "USDC");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Binance Coin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "BNB");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Cardano"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "ADA");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Dogecoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "DOGE");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Solana"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "SOL");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Litecoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddAssetDialog(context, "LTC");
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        "BUY",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Select Cryptocurrency to Sell"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text("Bitcoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "BTC");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Ethereum"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "ETH");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Tether"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "USDT");
                                  },
                                ),
                                ListTile(
                                  title: const Text("USD Coin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "USDC");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Binance Coin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "BNB");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Cardano"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "ADA");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Dogecoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "DOGE");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Solana"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "SOL");
                                  },
                                ),
                                ListTile(
                                  title: const Text("Litecoin"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showSellAssetDialog(context, "LTC");
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        "SELL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final sortedAssets = List<Asset>.from(_assets)..sort((a, b) => b.totalValue.compareTo(a.totalValue));
                final asset = sortedAssets[index];
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
                      final originalIndex = _assets.indexWhere((a) => a.currency == asset.currency);
                      if (originalIndex != -1) {
                        _assets.removeAt(originalIndex);
                      }
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        final originalIndex = _assets.indexWhere((a) => a.currency == asset.currency);
                        _showEditAssetDialog(context, asset, originalIndex);
                      },
                      child: ListTile(
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getColorForCurrency(asset.currency),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              asset.currency,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount: ${asset.amount}'),
                            Text('Average Price: \$${asset.averagePrice.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${asset.totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (asset.realPrice != null)
                              Text('Current: \$${asset.realPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),)
                          ],
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



