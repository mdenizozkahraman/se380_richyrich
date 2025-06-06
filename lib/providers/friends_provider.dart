import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/friend.dart';
import '../models/user.dart';
import '../models/asset.dart';

class FriendsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  
  List<Friend> _friends = [];
  Map<String, List<Asset>> _friendsPortfolios = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Friend> get friends => List.from(_friends);
  Map<String, List<Asset>> get friendsPortfolios => Map.from(_friendsPortfolios);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _auth.currentUser?.uid;

  FriendsProvider() {
    _auth.authStateChanges().listen((auth.User? user) {
      if (user != null) {
        loadFriends();
      } else {
        // Kullanıcı çıkış yaptığında state'i temizle
        _friends.clear();
        _friendsPortfolios.clear();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Arkadaşları yükle
  Future<void> loadFriends() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _setError(null);

      print('Loading friends for user: $_userId'); // Debug log

      final QuerySnapshot snapshot = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: _userId)
          .get(); // orderBy kaldırıldı çünkü index problemi yaratabilir

      print('Found ${snapshot.docs.length} friends'); // Debug log

      _friends = snapshot.docs
          .map((doc) {
            print('Friend doc data: ${doc.data()}'); // Debug log
            return Friend.fromJson(doc.id, doc.data() as Map<String, dynamic>);
          })
          .toList();

      // Tarihe göre sırala (app seviyesinde)
      _friends.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError('Arkadaşlar yüklenirken hata oluştu: $e');
      print('Error loading friends: $e');
    }
  }

  // Friend key ile arkadaş ekle
  Future<bool> addFriendByKey(String friendKey, User friendUser) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      // Kendini eklemeye çalışıyor mu kontrol et
      if (friendUser.uid == _userId) {
        _setError('Kendinizi arkadaş olarak ekleyemezsiniz');
        return false;
      }

      // Zaten arkadaş mı kontrol et
      final existingFriend = _friends.any((friend) => friend.friendId == friendUser.uid);
      if (existingFriend) {
        _setError('Bu kullanıcı zaten arkadaş listenizde');
        return false;
      }

      final newFriend = Friend(
        id: '', // Firestore otomatik ID verecek
        userId: _userId!,
        friendId: friendUser.uid,
        friendDisplayName: friendUser.displayName,
        friendEmail: friendUser.email,
        addedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('friends').add(newFriend.toJson());
      
      final addedFriend = Friend(
        id: docRef.id,
        userId: newFriend.userId,
        friendId: newFriend.friendId,
        friendDisplayName: newFriend.friendDisplayName,
        friendEmail: newFriend.friendEmail,
        addedAt: newFriend.addedAt,
      );

      _friends.insert(0, addedFriend);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Arkadaş eklenirken hata oluştu: $e');
      print('Error adding friend: $e');
      return false;
    }
  }

  // Arkadaşı sil
  Future<bool> removeFriend(String friendId) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      await _firestore.collection('friends').doc(friendId).delete();

      _friends.removeWhere((friend) => friend.id == friendId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Arkadaş silinirken hata oluştu: $e');
      print('Error removing friend: $e');
      return false;
    }
  }

  // Arkadaşın portfolyosunu yükle
  Future<void> loadFriendPortfolio(String friendUserId) async {
    try {
      _setError(null);

      final QuerySnapshot snapshot = await _firestore
          .collection('portfolios')
          .doc(friendUserId)
          .collection('assets')
          .orderBy('createdAt', descending: false)
          .get();

      final assets = snapshot.docs
          .map((doc) => Asset.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      _friendsPortfolios[friendUserId] = assets;
      notifyListeners();
    } catch (e) {
      _setError('Arkadaşın portfolyosu yüklenirken hata oluştu: $e');
      print('Error loading friend portfolio: $e');
    }
  }

  // Tüm arkadaşların portfolyolarını yükle
  Future<void> loadAllFriendsPortfolios() async {
    for (final friend in _friends) {
      await loadFriendPortfolio(friend.friendId);
    }
  }

  // Arkadaşın portfolyo değerini hesapla
  double getFriendPortfolioValue(String friendUserId, Map<String, double> currentPrices) {
    final assets = _friendsPortfolios[friendUserId] ?? [];
    return assets.fold(0.0, (sum, asset) {
      final price = currentPrices[asset.currency] ?? 0.0;
      return sum + (asset.amount * price);
    });
  }

  // Arkadaşları portfolio değerine göre sırala
  List<Friend> getRankedFriends(Map<String, double> currentPrices) {
    if (_friends.isEmpty) return [];
    
    final rankedFriends = List<Friend>.from(_friends);
    
    rankedFriends.sort((a, b) {
      final valueA = getFriendPortfolioValue(a.friendId, currentPrices);
      final valueB = getFriendPortfolioValue(b.friendId, currentPrices);
      return valueB.compareTo(valueA); // Büyükten küçüğe sırala
    });
    
    return rankedFriends;
  }

  // Kullanıcı dahil tüm katılımcıları sırala
  List<Map<String, dynamic>> getRankedAllParticipants(
    Map<String, double> currentPrices, 
    double userPortfolioValue, 
    String userId, 
    String userName, 
    String userEmail
  ) {
    List<Map<String, dynamic>> allParticipants = [];
    
    // Arkadaşları ekle
    for (final friend in _friends) {
      final portfolioValue = getFriendPortfolioValue(friend.friendId, currentPrices);
      allParticipants.add({
        'id': friend.friendId,
        'name': friend.friendDisplayName,
        'email': friend.friendEmail,
        'portfolioValue': portfolioValue,
        'isCurrentUser': false,
        'friend': friend,
      });
    }
    
    // Kullanıcıyı ekle
    allParticipants.add({
      'id': userId,
      'name': userName,
      'email': userEmail,
      'portfolioValue': userPortfolioValue,
      'isCurrentUser': true,
      'friend': null,
    });
    
    // Portfolio değerine göre sırala
    allParticipants.sort((a, b) => b['portfolioValue'].compareTo(a['portfolioValue']));
    
    return allParticipants;
  }

  // Kullanıcının kendi ranking pozisyonunu bul
  int getUserRankPosition(String userId, Map<String, double> currentPrices, double userPortfolioValue) {
    final allFriendsValues = _friends.map((friend) => 
      getFriendPortfolioValue(friend.friendId, currentPrices)
    ).toList();
    
    allFriendsValues.add(userPortfolioValue);
    allFriendsValues.sort((a, b) => b.compareTo(a)); // Büyükten küçüğe
    
    return allFriendsValues.indexOf(userPortfolioValue) + 1;
  }

  // Ranking istatistikleri al
  Map<String, dynamic> getRankingStats(Map<String, double> currentPrices, double userPortfolioValue) {
    if (_friends.isEmpty) {
      return {
        'userRank': 1,
        'totalParticipants': 1,
        'friendsAbove': 0,
        'friendsBelow': 0,
      };
    }
    
    final allValues = _friends.map((friend) => 
      getFriendPortfolioValue(friend.friendId, currentPrices)
    ).toList();
    
    final friendsAbove = allValues.where((value) => value > userPortfolioValue).length;
    final friendsBelow = allValues.where((value) => value < userPortfolioValue).length;
    
    return {
      'userRank': friendsAbove + 1,
      'totalParticipants': _friends.length + 1,
      'friendsAbove': friendsAbove,
      'friendsBelow': friendsBelow,
    };
  }

  void clearError() {
    _setError(null);
  }
} 