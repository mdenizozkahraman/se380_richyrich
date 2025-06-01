import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import 'friend_portfolio_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _friendKeyController = TextEditingController();

  @override
  void dispose() {
    _friendKeyController.dispose();
    super.dispose();
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
        ],
      ),
      body: Consumer2<FriendsProvider, UserProvider>(
        builder: (context, friendsProvider, userProvider, child) {
          if (userProvider.currentUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
} 