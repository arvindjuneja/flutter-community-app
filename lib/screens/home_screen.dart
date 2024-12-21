import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/view_models.dart';
import '../models/models.dart';
import 'news_detail_screen.dart';
import 'create_news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch news when the screen loads
    Future.microtask(() {
      context.read<NewsViewModel>().fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NewsViewModel>(
        builder: (context, newsViewModel, child) {
          if (newsViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (newsViewModel.newsList.isEmpty) {
            return const Center(child: Text('No news articles yet'));
          }

          return RefreshIndicator(
            onRefresh: () => newsViewModel.fetchNews(),
            child: ListView.builder(
              itemCount: newsViewModel.newsList.length,
              itemBuilder: (context, index) {
                final news = newsViewModel.newsList[index];
                return NewsCard(news: news);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateNewsScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final News news;

  const NewsCard({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(news: news),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageURL != null)
              Image.network(
                news.imageURL!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(news.authorName[0]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.authorName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              _formatDate(news.publishedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailScreen(news: news),
                            ),
                          );
                        },
                      ),
                      Text(news.commentsCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}