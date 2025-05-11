import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'language';
  static const String _currencyKey = 'currency';
  static const String _darkModeKey = 'darkMode';

  late SharedPreferences _prefs;
  String _language = 'English';
  String _currency = 'USD';
  bool _isDarkMode = true;

  String get language => _language;
  String get currency => _currency;
  bool get isDarkMode => _isDarkMode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> clearSettings() async {
    await _prefs.clear();
    _language = 'English';
    _currency = 'USD';
    _isDarkMode = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _language = _prefs.getString(_languageKey) ?? 'English';
    _currency = _prefs.getString(_currencyKey) ?? 'USD';
    _isDarkMode = _prefs.getBool(_darkModeKey) ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString(_languageKey, language);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    await _prefs.setString(_currencyKey, currency);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  String getText(String key) {
    if (_language == 'Türkçe') {
      return _turkishTexts[key] ?? key;
    }
    return _englishTexts[key] ?? key;
  }

  static const Map<String, String> _turkishTexts = {
    'settings': 'Ayarlar',
    'language': 'Dil',
    'currency': 'Para Birimi',
    'darkMode': 'Karanlık Mod',
    'help': 'Yardım',
    'english': 'İngilizce',
    'turkish': 'Türkçe',
    'try': 'TRY',
    'usd': 'USD',
    'eur': 'EUR',
    'market': 'Piyasa',
    'wallet': 'Cüzdan',
    'news': 'Haberler',
    'buy': 'Satın Al',
    'sell': 'Sat',
    'edit': 'Düzenle',
    'delete': 'Sil',
    'amount': 'Miktar',
    'price': 'Fiyat',
    'total': 'Toplam',
    'addAsset': 'Varlık Ekle',
    'editAsset': 'Varlık Düzenle',
    'sellAsset': 'Varlık Sat',
    'selectCrypto': 'Kripto Para Seçin',
    'enterAmount': 'Miktar Girin',
    'enterPrice': 'Fiyat Girin',
    'insufficientAmount': 'Yetersiz Miktar',
    'dataProvidedBy': 'Veriler CryptoCompare tarafından sağlanmaktadır',
    'portfolio': 'Portföy',
    'totalBalance': 'Toplam Bakiye',
    'assetDistribution': 'Varlık Dağılımı',
    'noAssets': 'Henüz varlık bulunmuyor',
    'addYourFirstAsset': 'İlk varlığınızı ekleyin',
    'helpContent': '''Uygulamayı kullanma kılavuzu:
• Satın Al: Portföyünüze yeni varlıklar ekleyin
• Sat: Portföyünüzden varlıkları çıkarın
• Piyasa: Güncel kripto para fiyatlarını görüntüleyin
• Cüzdan: Portföyünüzü yönetin
• Haberler: Kripto haberleriyle güncel kalın''',
    'cancel': 'İptal',
    'add': 'Ekle',
    'save': 'Kaydet',
    'deleteConfirmation': 'varlığını silmek istediğinizden emin misiniz?',
    'live': 'Canlı',
    'myWallet': 'Cüzdanım',
    'assets': 'Varlıklar',
    'averagePrice': 'Ortalama Fiyat',
    'current': 'Güncel',
    'selectCryptocurrency': 'Kripto Para Seçin',
    'selectCryptocurrencyToSell': 'Satmak için Kripto Para Seçin',
    'bitcoin': 'Bitcoin',
    'ethereum': 'Ethereum',
    'tether': 'Tether',
    'usdCoin': 'USD Coin',
    'binanceCoin': 'Binance Coin',
    'cardano': 'Cardano',
    'dogecoin': 'Dogecoin',
    'solana': 'Solana',
    'litecoin': 'Litecoin',
    'enterAmountToSell': 'Satmak için miktar girin',
    'enterAveragePrice': 'Ortalama alış fiyatını girin',
    'enterSellPrice': 'Satış fiyatını girin',
    'deleteAsset': 'Varlık Sil',
    'no': 'Hayır',
    'yes': 'Evet',
    'history':'Geçmiş',
    'noTransactions':'Henüz bir işlem kaydı bulunmuyor!',
  };

  static const Map<String, String> _englishTexts = {
    'settings': 'Settings',
    'language': 'Language',
    'currency': 'Currency',
    'darkMode': 'Dark Mode',
    'help': 'Help',
    'english': 'English',
    'turkish': 'Turkish',
    'try': 'TRY',
    'usd': 'USD',
    'eur': 'EUR',
    'market': 'Market',
    'wallet': 'Wallet',
    'news': 'News',
    'buy': 'Buy',
    'sell': 'Sell',
    'edit': 'Edit',
    'delete': 'Delete',
    'amount': 'Amount',
    'price': 'Price',
    'total': 'Total',
    'addAsset': 'Add Asset',
    'editAsset': 'Edit Asset',
    'sellAsset': 'Sell Asset',
    'selectCrypto': 'Select Cryptocurrency',
    'enterAmount': 'Enter Amount',
    'enterPrice': 'Enter Price',
    'insufficientAmount': 'Insufficient Amount',
    'dataProvidedBy': 'Data provided by CryptoCompare',
    'portfolio': 'Portfolio',
    'totalBalance': 'Total Balance',
    'assetDistribution': 'Asset Distribution',
    'noAssets': 'No assets yet',
    'addYourFirstAsset': 'Add your first asset',
    'helpContent': '''How to use the app:
• Buy: Add new assets to your portfolio
• Sell: Remove assets from your portfolio
• Market: View current cryptocurrency prices
• Wallet: Manage your portfolio
• News: Stay updated with crypto news''',
    'cancel': 'Cancel',
    'add': 'Add',
    'save': 'Save',
    'deleteConfirmation': 'asset?',
    'live': 'Live',
    'myWallet': 'My Wallet',
    'assets': 'Assets',
    'averagePrice': 'Average Price',
    'current': 'Current',
    'selectCryptocurrency': 'Select Cryptocurrency',
    'selectCryptocurrencyToSell': 'Select Cryptocurrency to Sell',
    'bitcoin': 'Bitcoin',
    'ethereum': 'Ethereum',
    'tether': 'Tether',
    'usdCoin': 'USD Coin',
    'binanceCoin': 'Binance Coin',
    'cardano': 'Cardano',
    'dogecoin': 'Dogecoin',
    'solana': 'Solana',
    'litecoin': 'Litecoin',
    'enterAmountToSell': 'Enter amount to sell',
    'enterAveragePrice': 'Enter average price',
    'enterSellPrice': 'Enter sell price',
    'deleteAsset': 'Delete Asset',
    'no': 'No',
    'yes': 'Yes',
    'history':'History',
    'noTransactions':'There is no transaction!',

  };
}