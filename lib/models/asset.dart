import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String currency;
  final double amount;
  final double averagePrice;
  double? realPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.currency,
    required this.amount,
    required this.averagePrice,
    this.realPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalValue => amount * (realPrice ?? 0);

  // Firestore'a kaydetmek için
  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'amount': amount,
      'averagePrice': averagePrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Firestore'dan okumak için
  factory Asset.fromJson(String id, Map<String, dynamic> json) {
    return Asset(
      id: id,
      currency: json['currency'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Asset'i güncellemek için kopyalama
  Asset copyWith({
    String? id,
    String? currency,
    double? amount,
    double? averagePrice,
    double? realPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      averagePrice: averagePrice ?? this.averagePrice,
      realPrice: realPrice ?? this.realPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 