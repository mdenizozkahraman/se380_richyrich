import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
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

  // Email/Password ile kayıt
  Future<bool> registerWithEmailPassword(String email, String password, String name) async {
    try {
      _setLoading(true);
      _setError(null);
      
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      _user = _auth.currentUser;
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'weak-password':
          _setError('Şifre çok zayıf');
          break;
        case 'email-already-in-use':
          _setError('Bu e-posta adresi zaten kullanımda');
          break;
        case 'invalid-email':
          _setError('Geçersiz e-posta adresi');
          break;
        default:
          _setError('Kayıt olurken hata oluştu: ${e.message}');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Beklenmeyen hata oluştu');
      return false;
    }
  }

  // Email/Password ile giriş
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'user-not-found':
          _setError('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
          break;
        case 'wrong-password':
          _setError('Yanlış şifre');
          break;
        case 'invalid-email':
          _setError('Geçersiz e-posta adresi');
          break;
        case 'user-disabled':
          _setError('Bu hesap devre dışı bırakılmış');
          break;
        default:
          _setError('Giriş yaparken hata oluştu: ${e.message}');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Beklenmeyen hata oluştu');
      return false;
    }
  }

  // Google ile giriş
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Google ile giriş yaparken hata oluştu');
      return false;
    }
  }

  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.sendPasswordResetEmail(email: email);
      
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      switch (e.code) {
        case 'user-not-found':
          _setError('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
          break;
        case 'invalid-email':
          _setError('Geçersiz e-posta adresi');
          break;
        default:
          _setError('Şifre sıfırlama e-postası gönderilirken hata oluştu');
      }
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Beklenmeyen hata oluştu');
      return false;
    }
  }

  // Çıkış
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      _setError('Çıkış yaparken hata oluştu');
    }
  }

  void clearError() {
    _setError(null);
  }
} 