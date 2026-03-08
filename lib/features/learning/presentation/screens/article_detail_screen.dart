import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  final Map<String, dynamic> article;

  @override
  Widget build(BuildContext context) {
    final title = article['title'] ?? 'Untitled';
    final description = article['description'] ?? '';
    final content = article['content'] ?? '';
    final category = article['category'] ?? 'General';
    final imageUrl = article['image_url'];
    final views = article['views'] ?? 0;
    final likes = article['likes'] ?? 0;
    final featured = article['featured'] ?? false;
    final createdAt = article['created_at'];

    DateTime? parsedDate;
    if (createdAt != null) {
      parsedDate = DateTime.tryParse(createdAt.toString());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article Detail'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$views',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (parsedDate != null)
                        Text(
                          _formatDate(parsedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
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

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
