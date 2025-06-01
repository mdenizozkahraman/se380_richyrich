import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:se380_richyrich/cryptocompare_service.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';
import 'package:se380_richyrich/providers/transaction_provider.dart';
import 'package:se380_richyrich/providers/portfolio_provider.dart';
import 'package:se380_richyrich/models/asset.dart';
import 'package:se380_richyrich/screens/settings.dart';

import '../transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Timer? _priceUpdateTimer;

  Future<void> _updateRealPrices() async {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
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

      Map<String, double> prices = {};
      
      if (data['BTC'] != null && data['BTC']['TRY'] != null) {
        prices['BTC'] = data['BTC']['TRY'].toDouble();
      }
      if (data['ETH'] != null && data['ETH']['TRY'] != null) {
        prices['ETH'] = data['ETH']['TRY'].toDouble();
      }
      if (data['USDT'] != null && data['USDT']['TRY'] != null) {
        prices['USDT'] = data['USDT']['TRY'].toDouble();
      }
      if (data['USDC'] != null && data['USDC']['TRY'] != null) {
        prices['USDC'] = data['USDC']['TRY'].toDouble();
      }
      if (data['BNB'] != null && data['BNB']['TRY'] != null) {
        prices['BNB'] = data['BNB']['TRY'].toDouble();
      }
      if (data['ADA'] != null && data['ADA']['TRY'] != null) {
        prices['ADA'] = data['ADA']['TRY'].toDouble();
      }
      if (data['DOGE'] != null && data['DOGE']['TRY'] != null) {
        prices['DOGE'] = data['DOGE']['TRY'].toDouble();
      }
      if (data['SOL'] != null && data['SOL']['TRY'] != null) {
        prices['SOL'] = data['SOL']['TRY'].toDouble();
      }
      if (data['LTC'] != null && data['LTC']['TRY'] != null) {
        prices['LTC'] = data['LTC']['TRY'].toDouble();
      }

      portfolioProvider.updateRealPrices(prices);
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
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
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
                onPressed: () async {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final newAmount = double.parse(amountController.text);
                    final newPrice = double.parse(priceController.text);

                    // Transaction'ı kaydet
                    transactionProvider.addTransaction(
                      Transaction(
                        type: 'BUY',
                        cryptocurrency: currency,
                        amount: newAmount,
                        price: newPrice,
                        timestamp: DateTime.now(),
                      ),
                    );

                    // Portfolyoya ekle
                    final success = await portfolioProvider.addOrUpdateAsset(currency, newAmount, newPrice);
                    
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(portfolioProvider.errorMessage ?? 'Bir hata oluştu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

  void _showEditAssetDialog(BuildContext context, Asset asset) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
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
                onPressed: () async {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final success = await portfolioProvider.updateAsset(
                      asset.id,
                      double.parse(amountController.text),
                      double.parse(priceController.text),
                    );
                    
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(portfolioProvider.errorMessage ?? 'Bir hata oluştu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
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
                onPressed: () => Navigator.pop(context),
                child: Text(settings.getText('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  if (amountController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final sellAmount = double.parse(amountController.text);
                    final sellPrice = double.parse(priceController.text);

                    // Transaction'ı kaydet
                    transactionProvider.addTransaction(
                      Transaction(
                        type: 'SELL',
                        cryptocurrency: currency,
                        amount: sellAmount,
                        price: sellPrice,
                        timestamp: DateTime.now(),
                      ),
                    );

                    // Portfolyodan çıkar
                    final success = await portfolioProvider.sellAsset(currency, sellAmount);
                    
                    if (success) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(portfolioProvider.errorMessage ?? 'Bir hata oluştu'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final assets = portfolioProvider.assets;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              settings.getText('myWallet'),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
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
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: portfolioProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                        '${_getCurrencySymbol(settings.currency)}${portfolioProvider.totalPortfolioValue.toStringAsFixed(2)}',
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
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.getText('assetDistribution'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: assets.isEmpty
                                ? [
                                    PieChartSectionData(
                                      value: 100,
                                      title: settings.getText('noAssets'),
                                      color: Colors.grey,
                                      radius: 100,
                                    ),
                                  ]
                                : assets.map((asset) {
                                  final totalValue = portfolioProvider.totalPortfolioValue;
                                  final percentage = totalValue == 0 ? 0.0 : (asset.totalValue / totalValue) * 100;
                                  final color = _getColorForCurrency(asset.currency);
                                  return PieChartSectionData(
                                    value: percentage,
                                    title: '${percentage.toStringAsFixed(1)}%',
                                    color: color,
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
                    ],
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
                                      settings.getText('selectCryptocurrencyToSell'),
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
                child: assets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              settings.getText('noAssets'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              settings.getText('addYourFirstAsset'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final sortedAssets = List<Asset>.from(assets)
                      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
                    final asset = sortedAssets[index];
                    return Dismissible(
                      key: Key(asset.id),
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
                      onDismissed: (direction) async {
                        await portfolioProvider.deleteAsset(asset.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            _showEditAssetDialog(context, asset);
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
      },
    );
  }
}
