import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:se380_richyrich/providers/auth_provider.dart';
import 'package:se380_richyrich/providers/settings_provider.dart';
import 'package:se380_richyrich/providers/transaction_provider.dart';
import 'package:se380_richyrich/providers/portfolio_provider.dart';
import 'screens/market.dart';
import 'screens/wallet.dart';
import 'screens/news.dart';
import 'screens/auth/login_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settings, auth, child) {
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
          home: auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
          routes: {
            '/home': (context) => const MainScreen(),
            '/login': (context) => const LoginScreen(),
          },
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