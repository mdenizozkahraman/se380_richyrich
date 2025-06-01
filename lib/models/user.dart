import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class User {
  final String uid;
  final String email;
  final String displayName;
  final String friendKey; // Arkadaş ekleme için özel key
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.friendKey,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore'a kaydetmek için
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'friendKey': friendKey,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Firestore'dan okumak için
  factory User.fromJson(String uid, Map<String, dynamic> json) {
    return User(
      uid: uid,
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      friendKey: json['friendKey'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Rastgele arkadaş key'i oluştur
  static String generateFriendKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // User'ı güncellemek için
  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? friendKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      friendKey: friendKey ?? this.friendKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 