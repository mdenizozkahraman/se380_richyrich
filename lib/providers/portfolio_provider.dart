import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';

class PortfolioProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Asset> get assets => List.from(_assets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _auth.currentUser?.uid;

  PortfolioProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadAssets();
      } else {
        // Kullanıcı çıkış yaptığında state'i temizle
        _assets.clear();
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

  // Kullanıcının portfolyo verilerini yükle
  Future<void> loadAssets() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final QuerySnapshot snapshot = await _firestore
          .collection('portfolios')
          .doc(_userId)
          .collection('assets')
          .orderBy('createdAt', descending: false)
          .get();

      _assets = snapshot.docs
          .map((doc) => Asset.fromJson(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Portfolyo verileri yüklenirken hata oluştu: $e');
      print('Error loading assets: $e');
    }
  }

  // Yeni varlık ekle veya mevcut varlığı güncelle
  Future<bool> addOrUpdateAsset(String currency, double amount, double price) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      // Aynı kripto paradan var mı kontrol et
      final existingAssetIndex = _assets.indexWhere((asset) => asset.currency == currency);

      if (existingAssetIndex != -1) {
        // Mevcut varlığı güncelle (weighted average)
        final existingAsset = _assets[existingAssetIndex];
        final totalAmount = existingAsset.amount + amount;
        final weightedAveragePrice = ((existingAsset.amount * existingAsset.averagePrice) + (amount * price)) / totalAmount;

        final updatedAsset = existingAsset.copyWith(
          amount: totalAmount,
          averagePrice: weightedAveragePrice,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('portfolios')
            .doc(_userId)
            .collection('assets')
            .doc(existingAsset.id)
            .update(updatedAsset.toJson());

        _assets[existingAssetIndex] = updatedAsset;
      } else {
        // Yeni varlık ekle
        final newAsset = Asset(
          id: '', // Firestore otomatik ID verecek
          currency: currency,
          amount: amount,
          averagePrice: price,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final docRef = await _firestore
            .collection('portfolios')
            .doc(_userId)
            .collection('assets')
            .add(newAsset.toJson());

        final addedAsset = newAsset.copyWith(id: docRef.id);
        _assets.add(addedAsset);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Varlık eklenirken hata oluştu: $e');
      print('Error adding asset: $e');
      return false;
    }
  }

  // Varlık sat (miktarı azalt)
  Future<bool> sellAsset(String currency, double amount) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      final existingAssetIndex = _assets.indexWhere((asset) => asset.currency == currency);
      
      if (existingAssetIndex == -1) {
        _setError('Bu varlık portfolyönüzde bulunmuyor');
        return false;
      }

      final existingAsset = _assets[existingAssetIndex];
      
      if (existingAsset.amount < amount) {
        _setError('Yetersiz miktar');
        return false;
      }

      final remainingAmount = existingAsset.amount - amount;

      if (remainingAmount <= 0) {
        // Varlığı tamamen sil
        await _firestore
            .collection('portfolios')
            .doc(_userId)
            .collection('assets')
            .doc(existingAsset.id)
            .delete();

        _assets.removeAt(existingAssetIndex);
      } else {
        // Miktarı güncelle
        final updatedAsset = existingAsset.copyWith(
          amount: remainingAmount,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('portfolios')
            .doc(_userId)
            .collection('assets')
            .doc(existingAsset.id)
            .update(updatedAsset.toJson());

        _assets[existingAssetIndex] = updatedAsset;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Varlık satılırken hata oluştu: $e');
      print('Error selling asset: $e');
      return false;
    }
  }

  // Varlığı güncelle
  Future<bool> updateAsset(String assetId, double amount, double averagePrice) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      final assetIndex = _assets.indexWhere((asset) => asset.id == assetId);
      
      if (assetIndex == -1) {
        _setError('Varlık bulunamadı');
        return false;
      }

      final updatedAsset = _assets[assetIndex].copyWith(
        amount: amount,
        averagePrice: averagePrice,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('portfolios')
          .doc(_userId)
          .collection('assets')
          .doc(assetId)
          .update(updatedAsset.toJson());

      _assets[assetIndex] = updatedAsset;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Varlık güncellenirken hata oluştu: $e');
      print('Error updating asset: $e');
      return false;
    }
  }

  // Varlığı sil
  Future<bool> deleteAsset(String assetId) async {
    if (_userId == null) return false;

    try {
      _setError(null);

      await _firestore
          .collection('portfolios')
          .doc(_userId)
          .collection('assets')
          .doc(assetId)
          .delete();

      _assets.removeWhere((asset) => asset.id == assetId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Varlık silinirken hata oluştu: $e');
      print('Error deleting asset: $e');
      return false;
    }
  }

  // Real-time fiyatları güncelle
  void updateRealPrices(Map<String, double> prices) {
    for (var i = 0; i < _assets.length; i++) {
      final currency = _assets[i].currency;
      if (prices.containsKey(currency)) {
        _assets[i] = _assets[i].copyWith(realPrice: prices[currency]);
      }
    }
    notifyListeners();
  }

  // Toplam portfolyo değeri
  double get totalPortfolioValue {
    return _assets.fold(0.0, (sum, asset) => sum + asset.totalValue);
  }

  void clearError() {
    _setError(null);
  }
} 