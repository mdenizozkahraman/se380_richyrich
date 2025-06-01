import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/friend.dart';
import '../providers/friends_provider.dart';
import '../providers/settings_provider.dart';
import '../cryptocompare_service.dart';

class FriendPortfolioScreen extends StatefulWidget {
  final Friend friend;

  const FriendPortfolioScreen({super.key, required this.friend});

  @override
  State<FriendPortfolioScreen> createState() => _FriendPortfolioScreenState();
}

class _FriendPortfolioScreenState extends State<FriendPortfolioScreen> {
  Map<String, double> _currentPrices = {};
  bool _isLoadingPrices = false;

  @override
  void initState() {
    super.initState();
    _loadFriendPortfolio();
  }

  Future<void> _loadFriendPortfolio() async {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    await friendsProvider.loadFriendPortfolio(widget.friend.friendId);
    
    final assets = friendsProvider.friendsPortfolios[widget.friend.friendId] ?? [];
    if (assets.isNotEmpty) {
      final currencies = assets.map((asset) => asset.currency).toSet().toList();
      await _loadCurrentPrices(currencies);
      
      // Update asset real prices
      for (final asset in assets) {
        asset.realPrice = _currentPrices[asset.currency] ?? 0.0;
      }
    }
  }

  Future<void> _loadCurrentPrices(List<String> currencies) async {
    if (currencies.isEmpty) return;

    setState(() {
      _isLoadingPrices = true;
    });

    try {
      final cryptoService = CryptoCompareService();
      final pricesData = await cryptoService.fetchPrices(currencies, 'USD');
      
      // Convert the data structure to Map<String, double>
      final Map<String, double> prices = {};
      for (final currency in currencies) {
        final currencyUpper = currency.toUpperCase();
        if (pricesData.containsKey(currencyUpper)) {
          final currencyData = pricesData[currencyUpper];
          if (currencyData is Map && currencyData.containsKey('USD')) {
            prices[currency] = currencyData['USD'].toDouble();
          }
        }
      }
      
      print('Loaded prices: $prices'); // Debug log
      
      setState(() {
        _currentPrices = prices;
        _isLoadingPrices = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPrices = false;
      });
      print('Error loading prices: $e');
    }
  }

  List<PieChartSectionData> _generatePieChartSections(List<dynamic> assets) {
    if (assets.isEmpty || _currentPrices.isEmpty) return [];

    double totalValue = 0;
    Map<String, double> assetValues = {};

    for (var asset in assets) {
      final price = _currentPrices[asset.currency] ?? 0.0;
      final value = asset.amount * price;
      assetValues[asset.currency] = value;
      totalValue += value;
    }

    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return assetValues.entries.map((entry) {
      final index = assetValues.keys.toList().indexOf(entry.key);
      final percentage = totalValue > 0 ? (entry.value / totalValue) * 100 : 0;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.friend.friendDisplayName} - Portfolio',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          final assets = friendsProvider.friendsPortfolios[widget.friend.friendId] ?? [];
          
          if (friendsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (assets.isEmpty) {
            return Center(
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
                    '${widget.friend.friendDisplayName} henüz portfolyoya varlık eklememiş',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final totalValue = friendsProvider.getFriendPortfolioValue(
            widget.friend.friendId, 
            _currentPrices
          );

          return RefreshIndicator(
            onRefresh: _loadFriendPortfolio,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toplam Değer Kartı
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Toplam Portfolio Değeri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isLoadingPrices)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalValue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pie Chart
                    if (_currentPrices.isNotEmpty && assets.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Portfolio Dağılımı',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: _generatePieChartSections(assets),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Varlıklar Listesi
                    const Text(
                      'Varlıklar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        final currentPrice = _currentPrices[asset.currency] ?? 0.0;
                        final totalAssetValue = asset.amount * currentPrice;
                        final profitLoss = totalAssetValue - (asset.amount * asset.averagePrice);
                        final profitLossPercentage = asset.averagePrice > 0 
                            ? ((currentPrice - asset.averagePrice) / asset.averagePrice) * 100 
                            : 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      asset.currency,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${totalAssetValue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Miktar: ${asset.amount.toStringAsFixed(6)}'),
                                    Text(
                                      'Mevcut Fiyat: \$${currentPrice.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ortalama Alış: \$${asset.averagePrice.toStringAsFixed(2)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    Text(
                                      '${profitLoss >= 0 ? '+' : ''}\$${profitLoss.toStringAsFixed(2)} (${profitLossPercentage >= 0 ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}%)',
                                      style: TextStyle(
                                        color: profitLoss >= 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 