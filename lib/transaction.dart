

class Transaction {
  final String type;
  final String cryptocurrency;
  final double amount;
  final double price;
  final DateTime timestamp;

  Transaction({
    required this.type,
    required this.cryptocurrency,
    required this.amount,
    required this.price,
    required this.timestamp,
});

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cryptocurrency': cryptocurrency,
      'amount': amount,
      'price': price,
      'timestamp': timestamp,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json){
    return Transaction(
        type: json['type'],
        cryptocurrency: json['cryptocurrency'],
        amount: json['amount'],
        price: json['price'],
        timestamp: json['timestamp']);
  }
}