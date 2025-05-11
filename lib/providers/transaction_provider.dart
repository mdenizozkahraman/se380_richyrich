import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:se380_richyrich/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionProvider extends ChangeNotifier {
  static const String _transactionsKey = 'transactions';
  late SharedPreferences _prefs;
  List<Transaction> _transactions = [];

  List<Transaction> get transactions => List.from(_transactions);

  TransactionProvider() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _prefs = await SharedPreferences.getInstance();
    final transactionsJson = _prefs.getStringList(_transactionsKey) ?? [];
    _transactions = transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
    _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // En yeni en üstte
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.insert(0, transaction); // En yeni işlemi başa ekle
    await _saveTransactions();
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    final transactionsJson = _transactions
        .map((transaction) => jsonEncode(transaction.toJson()))
        .toList();
    await _prefs.setStringList(_transactionsKey, transactionsJson);
  }

  Future<void> clearTransactions() async {
    _transactions.clear();
    await _prefs.remove(_transactionsKey);
    notifyListeners();
  }
}