import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String userId; // Arkadaşı ekleyen kişi
  final String friendId; // Eklenen arkadaş
  final String friendDisplayName; // Arkadaşın görünen adı
  final String friendEmail; // Arkadaşın emaili
  final DateTime addedAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendDisplayName,
    required this.friendEmail,
    required this.addedAt,
  });

  // Firestore'a kaydetmek için
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendDisplayName': friendDisplayName,
      'friendEmail': friendEmail,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  // Firestore'dan okumak için
  factory Friend.fromJson(String id, Map<String, dynamic> json) {
    return Friend(
      id: id,
      userId: json['userId'] ?? '',
      friendId: json['friendId'] ?? '',
      friendDisplayName: json['friendDisplayName'] ?? '',
      friendEmail: json['friendEmail'] ?? '',
      addedAt: (json['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
} 