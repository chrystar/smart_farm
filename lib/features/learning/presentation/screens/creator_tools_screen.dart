import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'article_detail_screen.dart';
import 'create_article_screen.dart';
import 'subscription_plans_screen.dart';
import 'my_videos_screen.dart';
import 'earnings_dashboard_screen.dart';
import 'support_help_screen.dart';

class CreatorToolsScreen extends StatefulWidget {
  const CreatorToolsScreen({Key? key}) : super(key: key);

  @override
  State<CreatorToolsScreen> createState() => _CreatorToolsScreenState();
}

class _CreatorToolsScreenState extends State<CreatorToolsScreen> {
  Map<String, dynamic>? _creatorProfile;
  bool _loading = true;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _articles = [];
  bool _articlesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCreatorProfile();
    _loadArticles();
  }

  Future<void> _loadCreatorProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      setState(() {
        _creatorProfile = response;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading creator profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadArticles() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('creator_articles')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _articles = List<Map<String, dynamic>>.from(response);
        _articlesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading articles: $e');
      setState(() => _articlesLoading = false);
    }
  }

  Future<void> _deleteArticle(String articleId) async {
    try {
      await Supabase.instance.client
          .from('creator_articles')
          .delete()
          .eq('id', articleId);

      setState(() {
        _articles.removeWhere((article) => article['id'] == articleId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting article: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting article: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Tools'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _creatorProfile == null
              ? const Center(
                  child: Text('Creator profile not found'),
                )
              : Column(
                  children: [
                    // Content Tabs
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: AppColors.primaryGreen,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.article),
                  label: 'Articles',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.videocam),
                  label: 'Videos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Subscribers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_membership),
                  label: 'Plans',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildArticlesView();
      case 1:
        return _buildVideosView();
      case 2:
        return _buildSubscribersView();
      case 3:
        return _buildPlansView();
      case 4:
        return _buildSettingsView();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildArticlesView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Articles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateArticleScreen(),
                        ),
                      ).then((_) => _loadArticles());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Article'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _articlesLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _articles.isEmpty
                        ? Center(
                            child: Column(
                              children: [
                                Icon(Icons.article_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'No articles yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Start creating articles to share your farming expertise',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _articles.length,
                            itemBuilder: (context, index) {
                              final article = _articles[index];
                              return _buildArticleCard(article);
                            },
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final title = article['title'] ?? 'Untitled';
    final description = article['description'] ?? '';
    final category = article['category'] ?? 'General';
    final imageUrl = article['image_url'];
    final views = article['views'] ?? 0;
    final likes = article['likes'] ?? 0;
    final createdAt = article['created_at'];
    final featured = article['featured'] ?? false;

    DateTime? parsedDate;
    if (createdAt != null) {
      parsedDate = DateTime.parse(createdAt.toString());
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.visibility,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '$views',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite_border,
                                size: 14, color: Colors.grey),
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
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(article['id']);
                          } else if (value == 'edit') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit article coming soon'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
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
  }

  void _showDeleteConfirmation(String articleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text(
          'Are you sure you want to delete this article? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArticle(articleId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
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

  Widget _buildVideosView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Videos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyVideosScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Manage Videos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.videocam_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Video Management',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload videos to engage with your subscribers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Subscribers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No subscribers yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create quality content to attract subscribers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
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

  Widget _buildPlansView() {
    return const SubscriptionPlansScreen();
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingItem(
              icon: Icons.person,
              title: 'Edit Profile',
              subtitle: 'Update your display name, bio, and profile picture',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile coming soon'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.monetization_on,
              title: 'Earnings',
              subtitle: 'View your earnings and payment history',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarningsDashboardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings coming soon'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help with creator tools',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportHelpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
