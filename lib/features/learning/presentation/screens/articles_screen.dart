import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'article_detail_screen.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({Key? key}) : super(key: key);

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _articles = [];
  List<String> _categories = ['All'];
  Map<String, Map<String, dynamic>> _creatorProfiles = {};
  Map<String, bool> _userSubscriptions = {}; // Track which creators user is subscribed to
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadArticles();
    _loadCategories();
    _loadUserSubscriptions();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('creator_articles')
          .select('category');

      final categories = <String>{'All'};
      for (var item in response) {
        final cat = item['category']?.toString();
        if (cat != null && cat.isNotEmpty) {
          categories.add(cat);
        }
      }

      if (mounted) {
        setState(() {
          _categories = categories.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadArticles() async {
    try {
      final response = await Supabase.instance.client
          .from('creator_articles')
          .select()
          .order('created_at', ascending: false);

      final articles = List<Map<String, dynamic>>.from(response);
      
      // Fetch creator profiles for all unique user_ids
      final userIds = articles.map((a) => a['user_id']).whereType<String>().toSet();
      for (final userId in userIds) {
        await _loadCreatorProfile(userId);
      }

      if (mounted) {
        setState(() {
          _articles = articles;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading articles: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCreatorProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        _creatorProfiles[userId] = response;
      }
    } catch (e) {
      debugPrint('Error loading creator profile for $userId: $e');
    }
  }

  Future<void> _loadUserSubscriptions() async {
    if (_currentUserId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('paid_subscriptions')
          .select('plan_id, creator_subscription_plans!inner(creator_id)')
          .eq('subscriber_id', _currentUserId!)
          .eq('status', 'active');

      final subscriptions = Map<String, bool>();
      for (var sub in response) {
        final creatorId = sub['creator_subscription_plans']['creator_id'];
        if (creatorId != null) {
          subscriptions[creatorId.toString()] = true;
        }
      }

      if (mounted) {
        setState(() {
          _userSubscriptions = subscriptions;
        });
      }
    } catch (e) {
      debugPrint('Error loading user subscriptions: $e');
    }
  }

  bool _isSubscribedToCreator(String creatorId) {
    return _userSubscriptions[creatorId] == true;
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _selectedCategory == 'All'
        ? _articles
        : _articles.where((a) => (a['category'] ?? '') == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primaryGreen,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Articles List
                Expanded(
                  child: filteredArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No articles found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different category',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            return _buildArticleCard(article);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final title = article['title'] ?? 'Untitled';
    final category = article['category'] ?? 'General';
    final readTime = _calculateReadTime(article['content'] ?? '');
    final featured = article['featured'] ?? false;
    final userId = article['user_id'] as String?;
    
    // Get creator profile
    final creatorProfile = userId != null ? _creatorProfiles[userId] : null;
    final creatorName = creatorProfile?['display_name'] ?? 'Unknown Creator';
    final creatorImageUrl = creatorProfile?['profile_picture_url'];
    
    // Check subscription status
    final isSubscribed = userId != null ? _isSubscribedToCreator(userId) : false;
    final isOwnArticle = userId == _currentUserId;

    return InkWell(
      onTap: () {
        // Allow access if user is subscribed, owns the article, or show paywall
        if (isSubscribed || isOwnArticle) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        } else {
          _showSubscriptionRequired(creatorName, userId);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          // Add colored border for subscription status
          side: isSubscribed 
            ? BorderSide(color: AppColors.primaryGreen.withOpacity(0.5), width: 2)
            : BorderSide.none,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Image with subscription badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: creatorImageUrl != null
                            ? Image.network(
                                creatorImageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 30,
                                ),
                              ),
                      ),
                      // Subscription check badge
                      if (isSubscribed)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Article Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Creator Name with subscription status
                        Row(
                          children: [
                            Text(
                              'by $creatorName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (isSubscribed) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 10,
                                      color: AppColors.primaryGreen,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Subscribed',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Category and Featured Badge
                        Row(
                          children: [
                            if (featured) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'Featured',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Read Time
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              readTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
            // Lock icon for non-subscribed articles
            if (!isSubscribed && !isOwnArticle)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionRequired(String creatorName, String? creatorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Subscription Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This article is exclusive to subscribers of $creatorName.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Subscribe to unlock:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow('Full access to all articles'),
                  _buildBenefitRow('Exclusive farming insights'),
                  _buildBenefitRow('Direct creator support'),
                  _buildBenefitRow('New content every week'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
              if (creatorId != null) {
                _navigateToSubscription(creatorId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscription(String creatorId) {
    // TODO: Navigate to subscription screen for this creator
    // This will be implemented when you integrate the subscription flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to subscription for creator: $creatorId'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  String _calculateReadTime(String content) {
    final wordCount = content.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }
}
