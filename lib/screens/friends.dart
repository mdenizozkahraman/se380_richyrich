import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/portfolio_provider.dart';
import '../cryptocompare_service.dart';
import 'friend_portfolio_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  final TextEditingController _friendKeyController = TextEditingController();
  late TabController _tabController;
  Map<String, double> _currentPrices = {};
  bool _isLoadingPrices = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _friendKeyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // Arkadaşları ve tüm portfolyoları yükle
    await friendsProvider.loadFriends();
    await friendsProvider.loadAllFriendsPortfolios();
    
    // Fiyatları yükle
    await _loadCurrentPrices();
  }

  Future<void> _loadCurrentPrices() async {
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // Tüm unique currency'leri topla
    Set<String> allCurrencies = {};
    
    // Kendi portfolyomuzdaki currency'ler
    for (final asset in portfolioProvider.assets) {
      allCurrencies.add(asset.currency);
    }
    
    // Arkadaşların portfolyolarındaki currency'ler
    for (final assets in friendsProvider.friendsPortfolios.values) {
      for (final asset in assets) {
        allCurrencies.add(asset.currency);
      }
    }
    
    if (allCurrencies.isEmpty) return;

    setState(() {
      _isLoadingPrices = true;
    });

    try {
      final cryptoService = CryptoCompareService();
      final pricesData = await cryptoService.fetchPrices(allCurrencies.toList(), 'USD');
      
      final Map<String, double> prices = {};
      for (final currency in allCurrencies) {
        final currencyUpper = currency.toUpperCase();
        if (pricesData.containsKey(currencyUpper)) {
          final currencyData = pricesData[currencyUpper];
          if (currencyData is Map && currencyData.containsKey('USD')) {
            prices[currency] = currencyData['USD'].toDouble();
          }
        }
      }
      
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

  void _showAddFriendDialog() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arkadaş Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Arkadaşınızın paylaştığı kodu girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: _friendKeyController,
              decoration: const InputDecoration(
                labelText: 'Arkadaş Kodu',
                hintText: 'Örnek: ABC12345',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _friendKeyController.clear();
              Navigator.pop(context);
            },
            child: Text(settings.getText('cancel')),
          ),
          TextButton(
            onPressed: () async {
              if (_friendKeyController.text.trim().isNotEmpty) {
                final friendKey = _friendKeyController.text.trim().toUpperCase();
                
                // Önce kullanıcıyı bul
                final friendUser = await userProvider.findUserByFriendKey(friendKey);
                
                if (friendUser != null) {
                  // Arkadaş ekle
                  final success = await friendsProvider.addFriendByKey(friendKey, friendUser);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Arkadaş başarıyla eklendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _friendKeyController.clear();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(friendsProvider.errorMessage ?? 'Arkadaş eklenirken hata oluştu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu kod ile kullanıcı bulunamadı!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Ekle',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void _copyFriendKey(String friendKey) {
    Clipboard.setData(ClipboardData(text: friendKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arkadaş kodunuz kopyalandı!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMyFriendKeyDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arkadaş Kodunuz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu kodu arkadaşlarınızla paylaşın:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    user.friendKey,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyFriendKey(user.friendKey),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopyala',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final success = await userProvider.regenerateFriendKey();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Arkadaş kodunuz yenilendi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                  _showMyFriendKeyDialog(); // Yeni kodu göster
                }
              },
              child: const Text('Kodu Yenile'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(settings.getText('cancel')),
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
        title: const Text(
          'Arkadaşlar',
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
        actions: [
          IconButton(
            onPressed: _showMyFriendKeyDialog,
            icon: const Icon(Icons.qr_code),
            tooltip: 'Kodumu Göster',
          ),
          IconButton(
            onPressed: _loadCurrentPrices,
            icon: _isLoadingPrices 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Fiyatları Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Arkadaşlar', icon: Icon(Icons.people)),
            Tab(text: 'Sıralama', icon: Icon(Icons.leaderboard)),
          ],
        ),
      ),
      body: Consumer3<FriendsProvider, UserProvider, PortfolioProvider>(
        builder: (context, friendsProvider, userProvider, portfolioProvider, child) {
          if (userProvider.currentUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(friendsProvider, userProvider, settings),
              _buildRankingTab(friendsProvider, userProvider, portfolioProvider, settings),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildFriendsTab(FriendsProvider friendsProvider, UserProvider userProvider, SettingsProvider settings) {
    if (friendsProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (friendsProvider.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz arkadaşınız yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arkadaş kodu ile yeni arkadaşlar ekleyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Arkadaş Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // My Friend Code Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Arkadaş Kodunuz',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userProvider.currentUser!.friendKey,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyFriendKey(userProvider.currentUser!.friendKey),
                        icon: const Icon(Icons.copy),
                        tooltip: 'Kopyala',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Friends List
        Expanded(
          child: ListView.builder(
            itemCount: friendsProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendsProvider.friends[index];
              final portfolioValue = friendsProvider.getFriendPortfolioValue(friend.friendId, _currentPrices);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      friend.friendDisplayName.isNotEmpty 
                          ? friend.friendDisplayName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    friend.friendDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.friendEmail),
                      Text(
                        'Portfolio Değeri: \$${portfolioValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Eklendi: ${friend.addedAt.day}/${friend.addedAt.month}/${friend.addedAt.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendPortfolioScreen(friend: friend),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance_wallet),
                        tooltip: 'Portfolyoyu Görüntüle',
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Arkadaşı Sil'),
                              content: Text('${friend.friendDisplayName} adlı arkadaşınızı silmek istediğinizden emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(settings.getText('no')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(settings.getText('yes')),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await friendsProvider.removeFriend(friend.id);
                            await _loadCurrentPrices(); // Refresh prices after removal
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Arkadaşı Sil',
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTab(FriendsProvider friendsProvider, UserProvider userProvider, PortfolioProvider portfolioProvider, SettingsProvider settings) {
    if (friendsProvider.isLoading || _isLoadingPrices) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (friendsProvider.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sıralama için arkadaş ekleyin',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arkadaşlarınızla portfolio değerlerinizi karşılaştırın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Kendi portfolio değerimizi hesapla
    final userPortfolioValue = portfolioProvider.assets.fold(0.0, (sum, asset) {
      final price = _currentPrices[asset.currency] ?? 0.0;
      return sum + (asset.amount * price);
    });

    // Tüm katılımcıları al (kullanıcı dahil)
    final allParticipants = friendsProvider.getRankedAllParticipants(
      _currentPrices, 
      userPortfolioValue, 
      userProvider.currentUser!.uid,
      userProvider.currentUser!.displayName,
      userProvider.currentUser!.email,
    );

    // Kullanıcının pozisyonunu bul
    final userPosition = allParticipants.indexWhere((p) => p['isCurrentUser'] == true) + 1;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Basit Pozisyon Kartı
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pozisyonunuz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$userPosition/${allParticipants.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Portfolio Değeri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${userPortfolioValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (userPosition == 1)
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                ],
              ),
            ),
          ),
          
          // Ranking Listesi Başlığı
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Sıralama',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Tüm katılımcıların listesi
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allParticipants.length,
            itemBuilder: (context, index) {
              final participant = allParticipants[index];
              final rank = index + 1;
              final isCurrentUser = participant['isCurrentUser'] as bool;
              final portfolioValue = participant['portfolioValue'] as double;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: isCurrentUser ? Colors.blue[50] : null,
                elevation: isCurrentUser ? 4 : 1,
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: rank <= 3 ? _getRankColor(rank) : (isCurrentUser ? Colors.blue[600] : Colors.grey[300]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: rank <= 3 
                              ? Icon(
                                  rank == 1 ? Icons.emoji_events : 
                                  rank == 2 ? Icons.military_tech : Icons.workspace_premium,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '$rank',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isCurrentUser ? Colors.white : Colors.black,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: isCurrentUser ? Colors.blue[600] : Colors.blue[100],
                        child: Text(
                          participant['name'].toString().isNotEmpty 
                              ? participant['name'].toString()[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        participant['name'].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.blue[800] : null,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    participant['email'].toString(),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.blue[600] : Colors.grey[600],
                    ),
                  ),
                  trailing: Text(
                    '\$${portfolioValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? _getRankColor(rank) : (isCurrentUser ? Colors.blue[800] : Colors.black),
                    ),
                  ),
                  onTap: isCurrentUser ? null : () {
                    // Sadece arkadaşların portfolyosuna gidebiliriz
                    final friend = participant['friend'];
                    if (friend != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendPortfolioScreen(friend: friend),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 80), // FloatingActionButton için boşluk
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[600]!; // Silver
      case 3:
        return Colors.orange[800]!; // Bronze
      default:
        return Colors.grey[400]!;
    }
  }
} 