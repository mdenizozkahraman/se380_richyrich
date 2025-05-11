import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:se380_richyrich/cryptocompare_service.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';
import 'package:se380_richyrich/providers/transaction_provider.dart';
import 'package:se380_richyrich/screens/settings.dart';

import '../transaction.dart';

class Asset {
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
    final service = CryptoCompareService();
    try {
      final data = await service.fetchPrices([
        'BTC',
        'ETH',
        'USDT',
        'USDC',
        'BNB',
        'ADA',
        'DOGE',
        'SOL',
        'LTC',
      ], 'TRY');

      setState(() {
        for (var asset in _assets) {
          switch (asset.currency) {
            case "BTC":
              if (data['BTC'] != null && data['BTC']['TRY'] != null) {
                asset.realPrice = data['BTC']['TRY'].toDouble();
              }
              break;
            case "ETH":
              if (data['ETH'] != null && data['ETH']['TRY'] != null) {
                asset.realPrice = data['ETH']['TRY'].toDouble();
              }
              break;
            case "USDT":
              if (data['USDT'] != null && data['USDT']['TRY'] != null) {
                asset.realPrice = data['USDT']['TRY'].toDouble();
              }
              break;
            case "USDC":
              if (data['USDC'] != null && data['USDC']['TRY'] != null) {
                asset.realPrice = data['USDC']['TRY'].toDouble();
              }
              break;
            case "BNB":
              if (data['BNB'] != null && data['BNB']['TRY'] != null) {
                asset.realPrice = data['BNB']['TRY'].toDouble();
              }
              break;
            case "ADA":
              if (data['ADA'] != null && data['ADA']['TRY'] != null) {
                asset.realPrice = data['ADA']['TRY'].toDouble();
              }
              break;
            case "DOGE":
              if (data['DOGE'] != null && data['DOGE']['TRY'] != null) {
                asset.realPrice = data['DOGE']['TRY'].toDouble();
              }
              break;
            case "SOL":
              if (data['SOL'] != null && data['SOL']['TRY'] != null) {
                asset.realPrice = data['SOL']['TRY'].toDouble();
              }
              break;
            case "LTC":
              if (data['LTC'] != null && data['LTC']['TRY'] != null) {
                asset.realPrice = data['LTC']['TRY'].toDouble();
              }
              break;
          }
        }
      });
    } catch (e) {
      print("Error fetching prices: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _updateRealPrices();
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRealPrices();
    });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'TRY':
        return '₺';
      case 'EUR':
        return '€';
      case 'USD':
      default:
        return '\$';
    }
  }

  Color _getColorForCurrency(String currency) {
    switch (currency) {
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
    final brightness =
        (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 128 ? Colors.black : Colors.white;
  }

  void _showAddAssetDialog(BuildContext context, String currency) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final TextEditingController amountController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("${settings.getText('add')} $currency"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: settings.getText('amount'),
                    hintText: settings.getText('enterAmount'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: settings.getText('averagePrice'),
                    hintText: settings.getText('enterAveragePrice'),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final newAmount = double.parse(amountController.text);
                    final newPrice = double.parse(priceController.text);

                    transactionProvider.addTransaction(
                      Transaction(
                        type: 'BUY',
                        cryptocurrency: currency,
                        amount: newAmount,
                        price: newPrice,
                        timestamp: DateTime.now(),
                      ),
                    );
                    setState(() {
                      final existingAssetIndex = _assets.indexWhere(
                        (asset) => asset.currency == currency,
                      );

                      if (existingAssetIndex != -1) {
                        final existingAsset = _assets[existingAssetIndex];
                        final totalAmount = existingAsset.amount + newAmount;
                        final weightedAveragePrice =
                            ((existingAsset.amount *
                                    existingAsset.averagePrice) +
                                (newAmount * newPrice)) /
                            totalAmount;

                        _assets[existingAssetIndex] = Asset(
                          currency: currency,
                          amount: totalAmount,
                          averagePrice: weightedAveragePrice,
                          realPrice: 0,
                        );
                      } else {
                        _assets.add(
                          Asset(
                            currency: currency,
                            amount: newAmount,
                            averagePrice: newPrice,
                            realPrice: 0,
                          ),
                        );
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  settings.getText('add'),
                  style: TextStyle(color: Colors.blue[500]),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditAssetDialog(BuildContext context, Asset asset, int index) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final TextEditingController amountController = TextEditingController(
      text: asset.amount.toString(),
    );
    final TextEditingController priceController = TextEditingController(
      text: asset.averagePrice.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("${settings.getText('edit')} ${asset.currency}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: settings.getText('amount'),
                    hintText: settings.getText('enterAmount'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: settings.getText('averagePrice'),
                    hintText: settings.getText('enterAveragePrice'),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(settings.getText('cancel')),
              ),
              TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    setState(() {
                      _assets[index] = Asset(
                        currency: asset.currency,
                        amount: double.parse(amountController.text),
                        averagePrice: double.parse(priceController.text),
                        realPrice: asset.realPrice,
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  settings.getText('save'),
                  style: TextStyle(color: Colors.blue[500]),
                ),
              ),
            ],
          ),
    );
  }

  void _showSellAssetDialog(BuildContext context, String currency) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final TextEditingController amountController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("${settings.getText('sell')} $currency"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: settings.getText('amount'),
                    hintText: settings.getText('enterAmountToSell'),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: settings.getText('price'),
                    hintText: settings.getText('enterSellPrice'),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {

                    final newAmount = double.parse(amountController.text);
                    final newPrice = double.parse(priceController.text);

                    transactionProvider.addTransaction(
                      Transaction(
                        type: 'SELL',
                        cryptocurrency: currency,
                        amount: newAmount,
                        price: newPrice,
                        timestamp: DateTime.now(),
                      ),
                    );
                    setState(() {
                      final existingAssetIndex = _assets.indexWhere(
                        (asset) => asset.currency == currency,
                      );

                      if (existingAssetIndex != -1) {
                        final existingAsset = _assets[existingAssetIndex];
                        if (existingAsset.amount >= newAmount) {
                          final remainingAmount =
                              existingAsset.amount - newAmount;
                          if (remainingAmount > 0) {
                            _assets[existingAssetIndex] = Asset(
                              currency: currency,
                              amount: remainingAmount,
                              averagePrice: existingAsset.averagePrice,
                              realPrice: existingAsset.realPrice,
                            );
                          } else {
                            _assets.removeAt(existingAssetIndex);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${settings.getText('insufficientAmount')} $currency',
                              ),
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
                  settings.getText('sell'),
                  style: TextStyle(color: Colors.red[500]),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.getText('myWallet'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    settings.getText('totalBalance'),
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_getCurrencySymbol(settings.currency)}${_assets.fold(0.0, (sum, asset) => sum + asset.totalValue).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
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
                    sections:
                        _assets.isEmpty
                            ? [
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
                            ]
                            : _assets.map((asset) {
                              final totalValue = _assets.fold(
                                0.0,
                                (sum, a) => sum + a.totalValue,
                              );
                              final percentage =
                                  (totalValue == 0 ||
                                          _assets.every(
                                            (a) => a.realPrice == null,
                                          ))
                                      ? (100 / _assets.length)
                                      : (asset.totalValue / totalValue) * 100;
                              final color = _getColorForCurrency(
                                asset.currency,
                              );
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
                Text(
                  settings.getText('assets'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(
                                  settings.getText('selectCryptocurrency'),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text(settings.getText('bitcoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "BTC");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('ethereum')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "ETH");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('tether')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "USDT");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('usdCoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "USDC");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        settings.getText('binanceCoin'),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "BNB");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('cardano')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "ADA");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('dogecoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "DOGE");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('solana')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showAddAssetDialog(context, "SOL");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('litecoin')),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        settings.getText('buy'),
                        style: const TextStyle(
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
                          builder:
                              (context) => AlertDialog(
                                title: Text(
                                  settings.getText(
                                    'selectCryptocurrencyToSell',
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text(settings.getText('bitcoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "BTC");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('ethereum')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "ETH");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('tether')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "USDT");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('usdCoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "USDC");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        settings.getText('binanceCoin'),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "BNB");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('cardano')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "ADA");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('dogecoin')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "DOGE");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('solana')),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSellAssetDialog(context, "SOL");
                                      },
                                    ),
                                    ListTile(
                                      title: Text(settings.getText('litecoin')),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        settings.getText('sell'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                final sortedAssets = List<Asset>.from(_assets)
                  ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
                final asset = sortedAssets[index];
                return Dismissible(
                  key: Key(asset.currency + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(settings.getText('deleteAsset')),
                            content: Text(
                              "${asset.currency} ${settings.getText('deleteConfirmation')}",
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text(settings.getText('no')),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: Text(settings.getText('yes')),
                              ),
                            ],
                          ),
                    );
                  },
                  onDismissed: (direction) {
                    setState(() {
                      final originalIndex = _assets.indexWhere(
                        (a) => a.currency == asset.currency,
                      );
                      if (originalIndex != -1) {
                        _assets.removeAt(originalIndex);
                      }
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        final originalIndex = _assets.indexWhere(
                          (a) => a.currency == asset.currency,
                        );
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${settings.getText('amount')}: ${asset.amount}',
                            ),
                            Text(
                              '${settings.getText('averagePrice')}: ${_getCurrencySymbol(settings.currency)}${asset.averagePrice.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_getCurrencySymbol(settings.currency)}${asset.totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (asset.realPrice != null)
                              Text(
                                '${settings.getText('current')}: ${_getCurrencySymbol(settings.currency)}${asset.realPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
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
