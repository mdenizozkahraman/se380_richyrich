import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';
import 'package:se380_richyrich/providers/transaction_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, TransactionProvider>(
      builder: (context, settings, transactionProvider, child) {

        final transactions = transactionProvider.transactions;
        return Scaffold(
            appBar: AppBar(
              title: Text(
                settings.getText('history'),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
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
            ),
          body: transactionProvider.transactions.isEmpty
              ? Center(
            child: Text(
              settings.getText('noTransactions'),
              style: const TextStyle(fontSize: 16),
            ),
          )
              : ListView.builder(
            itemCount: transactionProvider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactionProvider.transactions[index];
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp);
              final formattedPrice = NumberFormat.currency(
                symbol: settings.currency,
                decimalDigits: 2,
              ).format(transaction.price);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    transaction.type == 'BUY' ? Icons.add_circle : Icons.remove_circle,
                    color: transaction.type == 'BUY' ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    '${transaction.type} ${transaction.amount} ${transaction.cryptocurrency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${settings.getText('price')}: $formattedPrice'),
                      Text(formattedDate),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
}