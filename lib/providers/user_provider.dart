import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _auth.currentUser?.uid;

  UserProvider() {
    _auth.authStateChanges().listen((auth.User? user) async {
      print('Auth state changed: ${user?.uid}'); // Debug log
      if (user != null) {
        await loadUserProfile();
      } else {
        // Kullanıcı çıkış yaptığında state'i temizle
        _currentUser = null;
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

  // Kullanıcı profilini yükle veya oluştur
  Future<void> loadUserProfile() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final doc = await _firestore.collection('users').doc(_userId).get();
      
      if (doc.exists) {
        // Mevcut kullanıcı profilini yükle
        _currentUser = User.fromJson(_userId!, doc.data()!);
      } else {
        // Yeni kullanıcı profili oluştur
        await createUserProfile();
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Kullanıcı profili yüklenirken hata oluştu: $e');
      print('Error loading user profile: $e');
    }
  }

  // Yeni kullanıcı profili oluştur
  Future<bool> createUserProfile() async {
    if (_userId == null) return false;

    try {
      final authUser = _auth.currentUser!;
      
      final newUser = User(
        uid: _userId!,
        email: authUser.email ?? '',
        displayName: authUser.displayName ?? 'Kullanıcı',
        friendKey: User.generateFriendKey(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_userId).set(newUser.toJson());
      
      _currentUser = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Kullanıcı profili oluşturulurken hata oluştu: $e');
      print('Error creating user profile: $e');
      return false;
    }
  }

  // Kullanıcı profilini güncelle
  Future<bool> updateUserProfile({String? displayName}) async {
    if (_userId == null || _currentUser == null) return false;

    try {
      _setError(null);

      final updatedUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_userId).update(updatedUser.toJson());
      
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profil güncellenirken hata oluştu: $e');
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Friend key'i yenile
  Future<bool> regenerateFriendKey() async {
    if (_userId == null || _currentUser == null) return false;

    try {
      _setError(null);

      final updatedUser = _currentUser!.copyWith(
        friendKey: User.generateFriendKey(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(_userId).update(updatedUser.toJson());
      
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Friend key yenilenirken hata oluştu: $e');
      print('Error regenerating friend key: $e');
      return false;
    }
  }

  // Friend key ile kullanıcı bul
  Future<User?> findUserByFriendKey(String friendKey) async {
    try {
      _setError(null);

      final querySnapshot = await _firestore
          .collection('users')
          .where('friendKey', isEqualTo: friendKey)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromJson(doc.id, doc.data());
      }

      return null;
    } catch (e) {
      _setError('Kullanıcı aranırken hata oluştu: $e');
      print('Error finding user by friend key: $e');
      return null;
    }
  }

  void clearError() {
    _setError(null);
  }
} 