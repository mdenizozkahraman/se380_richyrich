import 'package:flutter/material.dart';
import 'package:se380_richyrich/screens/settings.dart';
import 'package:se380_richyrich/cryptocompare_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsItem {
  final String id;
  final String title;
  final String body;
  final String source;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final String categories;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.categories,
  });

  // API yanıtından NewsItem oluşturma
  factory NewsItem.fromApiResponse(Map<String, dynamic> data) {
    return NewsItem(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Başlık yok',
      body: data['body'] ?? 'İçerik yok',
      source: data['source'] ?? 'Kaynak belirtilmemiş',
      url: data['url'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://picsum.photos/800/400',
      publishedAt: data['publishedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['publishedAt'].toInt())
          : DateTime.now(),
      categories: data['categories'] ?? '',
    );
  }

  // Yayınlanma tarihini formatla
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}';
    }
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<NewsItem> newsItems = [];
  
  // CryptoCompare servisini kullan
  final CryptoCompareService _service = CryptoCompareService();
  
  // Kategori filtresi
  String? selectedCategory;
  final List<String> categories = ['All', 'Bitcoin', 'Ethereum', 'Altcoin', 'Blockchain', 'Mining', 'Trading', 'Regulation'];

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // CryptoCompare API'sinden haberleri çek
      final data = await _service.fetchNews(
        categories: selectedCategory != null && selectedCategory != 'All' ? selectedCategory : null,
        limit: 20,
      );
      
      final items = data.map((item) => NewsItem.fromApiResponse(item)).toList();
      
      setState(() {
        newsItems = items;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading news: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL açılamadı: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[900]!,
                Colors.blue[800]!,],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kategori filtreleme
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                final isSelected = selectedCategory == category || (selectedCategory == null && category == 'All');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = selected ? category : null;
                      });
                      loadNews();
                    },
                    backgroundColor: Colors.grey[800],
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Haberler
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : errorMessage != null
                ? _buildErrorWidget()
                : RefreshIndicator(
                    onRefresh: loadNews,
                    child: newsItems.isEmpty
                      ? const Center(child: Text('Haber bulunamadı'))
                      : ListView.builder(
                          itemCount: newsItems.length,
                          itemBuilder: (context, index) {
                            final news = newsItems[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.grey[850],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _launchUrl(news.url),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.network(
                                        news.imageUrl,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            color: Colors.grey[700],
                                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white54),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            news.title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[200],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            news.body.length > 150 
                                              ? '${news.body.substring(0, 150)}...' 
                                              : news.body,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                news.source,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                              Text(
                                                news.formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
          ),
          
          // Kaynak bilgisi
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Data provided by CryptoCompare',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Haberler yüklenemedi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage?.replaceAll('Exception: ', '') ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loadNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}