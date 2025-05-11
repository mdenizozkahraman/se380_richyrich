import 'package:flutter/material.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';
import 'package:se380_richyrich/providers/transaction_provider.dart';
import 'screens/market.dart';
import 'screens/wallet.dart';
import 'screens/news.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'RichyRich',
          theme: settings.isDarkMode
              ? ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[900],
          )
              : ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NewsScreen(),
    const MarketScreen(),
    const WalletScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[900]!,
              Colors.blue[800]!,
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.newspaper),
              label: settings.getText('news'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.trending_up),
              label: settings.getText('market'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet),
              label: settings.getText('wallet'),
            ),
          ],
        ),
      ),
    );
  }
}