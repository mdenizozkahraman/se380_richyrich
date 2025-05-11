import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CryptoCompareService {
  // API anahtarı ve temel URL
  final String _apiKey = 'dcbdf7a85b0513c6687676cfeb095e3ae69762d828aa45d8566ccf604d245c7a';
  final String _baseUrl = 'https://min-api.cryptocompare.com/data';
  
  // Önbellek için kullanılacak değişkenler
  static final Map<String, dynamic> _priceCache = {};
  static final Map<String, dynamic> _chartCache = {};
  static final Map<String, dynamic> _newsCache = {};
  static DateTime _lastPriceRequestTime = DateTime.now().subtract(const Duration(minutes: 5));
  static DateTime _lastChartRequestTime = DateTime.now().subtract(const Duration(minutes: 5));
  static DateTime _lastNewsRequestTime = DateTime.now().subtract(const Duration(minutes: 30));
  
  // Önbellek süresi (dakika cinsinden)
  static const int _priceCacheDurationMinutes = 5;
  static const int _chartCacheDurationMinutes = 30;
  static const int _newsCacheDurationMinutes = 30;
  
  // Önbellek kontrolü
  Future<bool> _shouldRefreshCache(String cacheType) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateKey = 'last_${cacheType}_update';
    final lastUpdate = prefs.getInt(lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    int cacheDuration;
    switch (cacheType) {
      case 'price':
        cacheDuration = _priceCacheDurationMinutes * 60 * 1000;
        break;
      case 'chart':
        cacheDuration = _chartCacheDurationMinutes * 60 * 1000;
        break;
      case 'news':
        cacheDuration = _newsCacheDurationMinutes * 60 * 1000;
        break;
      default:
        cacheDuration = 5 * 60 * 1000; // 5 dakika
    }
    
    if (now - lastUpdate > cacheDuration) {
      await prefs.setInt(lastUpdateKey, now);
      return true;
    }
    return false;
  }
  
  // Fiyat verilerini çekme
  Future<Map<String, dynamic>> fetchPrices(List<String> coinIds, String vsCurrency) async {
    final cacheKey = '${coinIds.join(',')}-$vsCurrency';
    
    // Önbellekte varsa ve güncel ise, önbellekten döndür
    if (_priceCache.containsKey(cacheKey) && 
        DateTime.now().difference(_lastPriceRequestTime).inMinutes < _priceCacheDurationMinutes) {
      print('Fiyatlar önbellekten alınıyor');
      return _priceCache[cacheKey];
    }
    
    // Önbelleği güncelleme zamanı gelmiş mi kontrol et
    final shouldRefresh = await _shouldRefreshCache('price');
    if (!shouldRefresh && _priceCache.containsKey(cacheKey)) {
      print('Fiyatlar önbellekten alınıyor (zaman kontrolü)');
      return _priceCache[cacheKey];
    }
    
    try {
      final fsyms = coinIds.join(',');
      final url = Uri.parse('$_baseUrl/pricemulti?fsyms=$fsyms&tsyms=$vsCurrency&api_key=$_apiKey');
      
      print('API isteği gönderiliyor: $url');
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
        }
      );
      
      print('API yanıtı: ${response.statusCode}');
      print('Yanıt gövdesi: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Yanıt yapısını kontrol et
        if (data is Map<String, dynamic>) {
          print('Veri yapısı doğru: Map<String, dynamic>');
          _priceCache[cacheKey] = data;
          _lastPriceRequestTime = DateTime.now();
          return data;
        } else {
          print('Beklenmeyen veri yapısı: ${data.runtimeType}');
          throw Exception('Beklenmeyen API yanıt formatı');
        }
      } else {
        print('API Hatası: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        
        // Hata durumunda önbellekte veri varsa onu kullan
        if (_priceCache.containsKey(cacheKey)) {
          return _priceCache[cacheKey];
        }
        
        // Önbellekte veri yoksa mock veri döndür
        return _getMockPrices(coinIds, vsCurrency);
      }
    } catch (e) {
      print('Fiyat çekme hatası: $e');
      
      // Hata durumunda önbellekte veri varsa onu kullan
      if (_priceCache.containsKey(cacheKey)) {
        return _priceCache[cacheKey];
      }
      
      // Önbellekte veri yoksa mock veri döndür
      return _getMockPrices(coinIds, vsCurrency);
    }
  }
  
  // Grafik verilerini çekme
  Future<List<Map<String, dynamic>>> fetchMarketChart(String coinId, String vsCurrency, int days) async {
    final cacheKey = '$coinId-$vsCurrency-$days';
    
    // Önbellekte varsa ve güncel ise, önbellekten döndür
    if (_chartCache.containsKey(cacheKey) && 
        DateTime.now().difference(_lastChartRequestTime).inMinutes < _chartCacheDurationMinutes) {
      print('Grafik verileri önbellekten alınıyor');
      return _chartCache[cacheKey];
    }
    
    // Önbelleği güncelleme zamanı gelmiş mi kontrol et
    final shouldRefresh = await _shouldRefreshCache('chart');
    if (!shouldRefresh && _chartCache.containsKey(cacheKey)) {
      print('Grafik verileri önbellekten alınıyor (zaman kontrolü)');
      return _chartCache[cacheKey];
    }
    
    try {
      String endpoint;
      if (days <= 1) {
        endpoint = 'histominute';
        days = 1440; // 1 gün = 1440 dakika
      } else if (days <= 7) {
        endpoint = 'histohour';
        days = days * 24; // Gün sayısı * 24 saat
      } else {
        endpoint = 'histoday';
      }
      
      final url = Uri.parse('$_baseUrl/v2/$endpoint?fsym=$coinId&tsym=$vsCurrency&limit=$days&api_key=$_apiKey');
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
        }
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'Success' && data['Data'] != null && data['Data']['Data'] != null) {
          final historyData = data['Data']['Data'] as List;
          final result = historyData.map((item) => {
            'timestamp': item['time'] * 1000.0, // Unix timestamp'i milisaniyeye çevir
            'price': item['close'].toDouble(),
          }).toList();
          
          _chartCache[cacheKey] = result;
          _lastChartRequestTime = DateTime.now();
          return result;
        } else {
          print('API Yanıtı Hatası: ${data['Message'] ?? 'Bilinmeyen hata'}');
          
          // Önbellekte veri varsa onu kullan
          if (_chartCache.containsKey(cacheKey)) {
            return _chartCache[cacheKey];
          }
          
          // Önbellekte veri yoksa mock veri döndür
          return _getMockChartData(days);
        }
      } else {
        print('API Hatası: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        
        // Hata durumunda önbellekte veri varsa onu kullan
        if (_chartCache.containsKey(cacheKey)) {
          return _chartCache[cacheKey];
        }
        
        // Önbellekte veri yoksa mock veri döndür
        return _getMockChartData(days);
      }
    } catch (e) {
      print('Grafik verisi çekme hatası: $e');
      
      // Hata durumunda önbellekte veri varsa onu kullan
      if (_chartCache.containsKey(cacheKey)) {
        return _chartCache[cacheKey];
      }
      
      // Önbellekte veri yoksa mock veri döndür
      return _getMockChartData(days);
    }
  }
  
  // Haber verilerini çekme
  Future<List<Map<String, dynamic>>> fetchNews({String? categories, int limit = 10}) async {
    final cacheKey = 'news-${categories ?? 'all'}-$limit';
    
    // Önbellekte varsa ve güncel ise, önbellekten döndür
    if (_newsCache.containsKey(cacheKey) && 
        DateTime.now().difference(_lastNewsRequestTime).inMinutes < _newsCacheDurationMinutes) {
      print('Haberler önbellekten alınıyor');
      return _newsCache[cacheKey];
    }
    
    // Önbelleği güncelleme zamanı gelmiş mi kontrol et
    final shouldRefresh = await _shouldRefreshCache('news');
    if (!shouldRefresh && _newsCache.containsKey(cacheKey)) {
      print('Haberler önbellekten alınıyor (zaman kontrolü)');
      return _newsCache[cacheKey];
    }
    
    try {
      String urlStr = '$_baseUrl/v2/news/?lang=EN&sortOrder=popular&api_key=$_apiKey';
      if (categories != null && categories.isNotEmpty) {
        urlStr += '&categories=$categories';
      }
      urlStr += '&extraParams=RichyRich_App';
      
      final url = Uri.parse(urlStr);
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
        }
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Data'] != null) {
          final newsData = data['Data'] as List;
          final result = newsData.take(limit).map((item) => {
            'id': item['id'],
            'title': item['title'],
            'url': item['url'],
            'body': item['body'],
            'imageUrl': item['imageurl'],
            'source': item['source'],
            'publishedAt': item['published_on'] * 1000.0, // Unix timestamp'i milisaniyeye çevir
            'tags': item['tags'],
            'categories': item['categories'],
          }).toList();
          
          _newsCache[cacheKey] = result;
          _lastNewsRequestTime = DateTime.now();
          return result;
        } else {
          print('API Yanıtı Hatası: ${data['Message'] ?? 'Bilinmeyen hata'}');
          
          // Önbellekte veri varsa onu kullan
          if (_newsCache.containsKey(cacheKey)) {
            return _newsCache[cacheKey];
          }
          
          // Önbellekte veri yoksa mock veri döndür
          return _getMockNews(limit);
        }
      } else {
        print('API Hatası: ${response.statusCode}');
        print('Yanıt: ${response.body}');
        
        // Hata durumunda önbellekte veri varsa onu kullan
        if (_newsCache.containsKey(cacheKey)) {
          return _newsCache[cacheKey];
        }
        
        // Önbellekte veri yoksa mock veri döndür
        return _getMockNews(limit);
      }
    } catch (e) {
      print('Haber çekme hatası: $e');
      
      // Hata durumunda önbellekte veri varsa onu kullan
      if (_newsCache.containsKey(cacheKey)) {
        return _newsCache[cacheKey];
      }
      
      // Önbellekte veri yoksa mock veri döndür
      return _getMockNews(limit);
    }
  }
  
  // Mock fiyat verisi
  Map<String, dynamic> _getMockPrices(List<String> coinIds, String vsCurrency) {
    final result = <String, dynamic>{};
    
    for (final coinId in coinIds) {
      double basePrice;
      switch (coinId.toLowerCase()) {
        case 'btc':
        case 'bitcoin':
          basePrice = 2000000.0;
          break;
        case 'eth':
        case 'ethereum':
          basePrice = 120000.0;
          break;
        case 'usdt':
        case 'tether':
          basePrice = 30.0;
          break;
        case 'usdc':
        case 'usd-coin':
          basePrice = 30.0;
          break;
        case 'bnb':
        case 'binancecoin':
          basePrice = 9000.0;
          break;
        case 'ada':
        case 'cardano':
          basePrice = 15.0;
          break;
        case 'doge':
        case 'dogecoin':
          basePrice = 5.0;
          break;
        case 'sol':
        case 'solana':
          basePrice = 3500.0;
          break;
        case 'ltc':
        case 'litecoin':
          basePrice = 2500.0;
          break;
        default:
          basePrice = 100.0;
      }
      
      result[coinId.toUpperCase()] = {
        vsCurrency.toLowerCase(): basePrice + Random().nextDouble() * (basePrice * 0.05),
      };
    }
    
    return result;
  }
  
  // Mock grafik verisi
  List<Map<String, dynamic>> _getMockChartData(int days) {
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;
    
    // Başlangıç fiyatı ve değişim aralığı belirleme
    double basePrice;
    double priceRange;
    
    switch (days) {
      case 1:
        basePrice = 2000000.0;
        priceRange = 20000.0;
        break;
      case 7:
        basePrice = 2000000.0;
        priceRange = 50000.0;
        break;
      case 30:
        basePrice = 1950000.0;
        priceRange = 100000.0;
        break;
      case 90:
        basePrice = 1900000.0;
        priceRange = 200000.0;
        break;
      case 365:
        basePrice = 1800000.0;
        priceRange = 400000.0;
        break;
      default:
        basePrice = 2000000.0;
        priceRange = 50000.0;
    }
    
    // Gerçekçi fiyat hareketi oluştur
    double lastPrice = basePrice;
    
    for (int i = days; i >= 0; i--) {
      final timestamp = now - (i * dayInMs ~/ days);
      // Küçük rastgele değişimler
      final change = (Random().nextDouble() - 0.5) * (priceRange / days);
      lastPrice += change;
      
      // Fiyat asla çok düşmesin
      if (lastPrice < basePrice - priceRange) {
        lastPrice = basePrice - priceRange + Random().nextDouble() * 10000;
      }
      
      // Fiyat asla çok yükselmesin
      if (lastPrice > basePrice + priceRange) {
        lastPrice = basePrice + priceRange - Random().nextDouble() * 10000;
      }
      
      result.add({
        'timestamp': timestamp.toDouble(),
        'price': lastPrice,
      });
    }
    
    return result;
  }
  
  // Mock haber verisi
  List<Map<String, dynamic>> _getMockNews(int limit) {
    final List<Map<String, dynamic>> mockNews = [
      {
        'id': '1',
        'title': 'Bitcoin Fiyatı Yeni Rekor Seviyeye Ulaştı',
        'url': 'https://example.com/bitcoin-new-high',
        'body': 'Bitcoin, bugün yeni bir rekor kırarak tüm zamanların en yüksek seviyesine ulaştı. Analistler, kurumsal yatırımcıların artan ilgisinin bu yükselişte etkili olduğunu belirtiyor.',
        'imageUrl': 'https://example.com/images/bitcoin.jpg',
        'source': 'Crypto News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Bitcoin,BTC,ATH',
        'categories': 'Bitcoin,Market',
      },
      {
        'id': '2',
        'title': 'Ethereum 2.0 Güncellemesi Yaklaşıyor',
        'url': 'https://example.com/ethereum-update',
        'body': 'Ethereum ağı, yakında büyük bir güncelleme alacak. Bu güncelleme ile birlikte, ağın enerji tüketimi azalacak ve işlem hızları artacak.',
        'imageUrl': 'https://example.com/images/ethereum.jpg',
        'source': 'ETH News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Ethereum,ETH,Update',
        'categories': 'Ethereum,Technology',
      },
      {
        'id': '3',
        'title': 'Kripto Para Düzenlemeleri Geliyor',
        'url': 'https://example.com/crypto-regulations',
        'body': 'Dünya genelinde kripto para düzenlemeleri hız kazanıyor. Birçok ülke, kripto paraların yasal statüsünü belirlemeye çalışıyor.',
        'imageUrl': 'https://example.com/images/regulations.jpg',
        'source': 'Crypto Insider',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 8)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Regulations,Government,Crypto',
        'categories': 'Regulation,General',
      },
      {
        'id': '4',
        'title': 'NFT Pazarı Büyümeye Devam Ediyor',
        'url': 'https://example.com/nft-market',
        'body': 'NFT pazarı, geçtiğimiz ay rekor seviyede işlem hacmine ulaştı. Sanat eserleri ve dijital koleksiyonlar, yatırımcıların ilgisini çekmeye devam ediyor.',
        'imageUrl': 'https://example.com/images/nft.jpg',
        'source': 'NFT World',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 12)).millisecondsSinceEpoch.toDouble(),
        'tags': 'NFT,Art,Digital',
        'categories': 'NFT,Market',
      },
      {
        'id': '5',
        'title': 'DeFi Protokolleri Yeni Rekor Kırdı',
        'url': 'https://example.com/defi-record',
        'body': 'Merkeziyetsiz finans (DeFi) protokollerinde kilitli toplam değer, 100 milyar doları aştı. Bu, sektörün hızla büyüdüğünü gösteriyor.',
        'imageUrl': 'https://example.com/images/defi.jpg',
        'source': 'DeFi News',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 18)).millisecondsSinceEpoch.toDouble(),
        'tags': 'DeFi,Finance,Record',
        'categories': 'DeFi,Market',
      },
      {
        'id': '6',
        'title': 'Büyük Şirketler Bitcoin Almaya Devam Ediyor',
        'url': 'https://example.com/companies-bitcoin',
        'body': 'Fortune 500 listesindeki şirketler, Bitcoin satın almaya devam ediyor. Bu durum, kurumsal adaptasyonun arttığını gösteriyor.',
        'imageUrl': 'https://example.com/images/corporate.jpg',
        'source': 'Business Crypto',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Bitcoin,Corporate,Adoption',
        'categories': 'Bitcoin,Business',
      },
      {
        'id': '7',
        'title': 'Yeni Bir Kripto Para Birimi Piyasaya Sürüldü',
        'url': 'https://example.com/new-crypto',
        'body': 'Yeni bir kripto para birimi, bugün büyük bir ICO ile piyasaya sürüldü. Proje, sürdürülebilir blockchain teknolojisine odaklanıyor.',
        'imageUrl': 'https://example.com/images/newcoin.jpg',
        'source': 'ICO Alert',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 36)).millisecondsSinceEpoch.toDouble(),
        'tags': 'ICO,Newcoin,Launch',
        'categories': 'ICO,Altcoin',
      },
      {
        'id': '8',
        'title': 'Kripto Para Madenciliği Çevresel Etkileri',
        'url': 'https://example.com/mining-environment',
        'body': 'Kripto para madenciliğinin çevresel etkileri tartışılmaya devam ediyor. Bazı şirketler, sürdürülebilir madencilik çözümleri geliştiriyor.',
        'imageUrl': 'https://example.com/images/mining.jpg',
        'source': 'Green Crypto',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 48)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Mining,Environment,Sustainability',
        'categories': 'Mining,Environment',
      },
      {
        'id': '9',
        'title': 'Kripto Para ATM\'leri Yaygınlaşıyor',
        'url': 'https://example.com/crypto-atms',
        'body': 'Dünya genelinde kripto para ATM\'lerinin sayısı hızla artıyor. Bu, kripto paraların günlük kullanımının yaygınlaştığını gösteriyor.',
        'imageUrl': 'https://example.com/images/atm.jpg',
        'source': 'Crypto Daily',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 60)).millisecondsSinceEpoch.toDouble(),
        'tags': 'ATM,Adoption,Usage',
        'categories': 'Adoption,Infrastructure',
      },
      {
        'id': '10',
        'title': 'Blockchain Teknolojisi Sağlık Sektöründe',
        'url': 'https://example.com/blockchain-healthcare',
        'body': 'Blockchain teknolojisi, sağlık sektöründe veri güvenliği ve hasta kayıtlarının yönetimi için kullanılmaya başlandı.',
        'imageUrl': 'https://example.com/images/healthcare.jpg',
        'source': 'Tech Health',
        'publishedAt': DateTime.now().subtract(const Duration(hours: 72)).millisecondsSinceEpoch.toDouble(),
        'tags': 'Blockchain,Healthcare,Technology',
        'categories': 'Blockchain,Healthcare',
      },
    ];
    
    return mockNews.take(limit).toList();
  }
} 