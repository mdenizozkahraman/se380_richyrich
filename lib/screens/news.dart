import 'package:flutter/material.dart';
import 'package:se380_richyrich/screens/settings.dart';

class NewsItem{
  final String title;
  final String description;
  final String source;
  final String date;
  final String imageUrl;

  NewsItem({
    required this.title,
    required this.description,
    required this.source,
    required this.date,
    required this.imageUrl
});

}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool isLoading = false;

  final List<NewsItem> newsItems = [
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/411/5000/2358.jpg?hmac=YjkATffpMa8rh663_FXDsGY0W-Y0hAPfqpjXZoP65hQ",
    ),
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/400/5000/3333.jpg?hmac=XKAazck_prwhbeyjBv4hERt3PeQAn0aX52O92xOXdrM",
    ),
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/391/2980/2151.jpg?hmac=Vm7g1uyLxiCTfcFr1aXyYGRwqi7LMjpXzkatkqekPGQ",
    ),
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/384/5000/3333.jpg?hmac=2GOxaQgXQ8kSAxRCFBixRObEW77GSX6a874FK-ZsvOM",
    ),
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/382/3264/2448.jpg?hmac=h54Mr6ckCa-SPz2TZeUF_uvV_Qc8OhXbTSGw3ZDdxCI",
    ),
    NewsItem(
      title: "EUR/USD shows stability at 1.08",
      description: "The Euro maintains its position against the Dollar at 1.08, as European markets show signs of recovery.",
      source: "Financial Times",
      date: "8 hours ago",
      imageUrl: "https://fastly.picsum.photos/id/392/5000/3333.jpg?hmac=vCaGuB6rQAiaofdQHatQL4DHgkyR2l-Ms9GWAL63CBQ",
    ),
  ];

  Future<void> loadNews() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isLoading = false;
    });
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
      body: isLoading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: loadNews,
        child: ListView.builder(
          itemCount: newsItems.length,
          itemBuilder: (context, index) {
            final news = newsItems[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRect(
                    child: Image.network(
                      news.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8,),
                        Text(
                          news.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              news.source,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Text("  "),
                            Text(
                              news.date,
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
            );
          },
        ),
      ),
    );
  }
}