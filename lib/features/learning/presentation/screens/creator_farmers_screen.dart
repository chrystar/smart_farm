import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'subscription_checkout_screen.dart';
import 'creator_tools_screen.dart';

class CreatorFarmersScreen extends StatefulWidget {
  const CreatorFarmersScreen({Key? key}) : super(key: key);

  @override
  State<CreatorFarmersScreen> createState() => _CreatorFarmersScreenState();
}

class _CreatorFarmersScreenState extends State<CreatorFarmersScreen> {
  List<Map<String, dynamic>> _creators = [];
  String _searchQuery = '';
  String _sortBy = 'newest';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _currentUserId = user?.id;
    _fetchCreators();
  }

  Future<void> _fetchCreators() async {
    try {
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select('id, user_id, display_name, bio, profile_picture_url, approved, created_at')
          .eq('approved', true)
          .order('created_at', ascending: false);
      setState(() {
        _creators = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching creators: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredCreators {
    var creators = _creators
        .where((creator) {
          final displayName = creator['display_name']?.toString().toLowerCase() ?? '';
          final bio = creator['bio']?.toString().toLowerCase() ?? '';
          final searchLower = _searchQuery.toLowerCase();
          return displayName.contains(searchLower) || bio.contains(searchLower);
        })
        .toList();

    // Sort
    switch (_sortBy) {
      case 'newest':
        creators.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        break;
      default:
        creators.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    }

    return creators;
  }

  Future<void> _navigateToCreatorTools() async {
    try {
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to access creator tools'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if user is a creator
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select('id, user_id, approved')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to become a creator first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!response['approved'] ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your creator profile is pending approval'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatorToolsScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to creator tools: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBecomeCreatorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Become a Creator',
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
            const Text(
              'To become a creator, you must first subscribe to the Smart Farm premium app subscription.',
              style: TextStyle(fontSize: 14),
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
                        'As a creator, you can:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBenefitRow('Publish articles & tutorials'),
                  _buildBenefitRow('Create subscription plans'),
                  _buildBenefitRow('Earn from subscribers'),
                  _buildBenefitRow('Build your farming community'),
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
            onPressed: () async {
              Navigator.pop(context);
              await _checkSubscriptionAndApply();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Apply Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSubscriptionAndApply() async {
    if (_currentUserId == null) return;

    try {
      // Check if user has app premium subscription (need to check with SubscriptionProvider)
      // For now, we'll check if user has any active subscriptions to the app platform
      // This would integrate with RevenueCat or your subscription service
      
      // TODO: Replace with actual app subscription check via SubscriptionProvider
      // final isPremium = context.read<SubscriptionProvider>().isPremium;
      
      // For demonstration, we'll show the subscription required dialog
      if (mounted) {
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
                    'Premium Subscription Required',
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
                const Text(
                  'You must have an active Smart Farm premium subscription to become a creator.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Premium subscription includes:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildRequirementRow('Access to creator tools'),
                      _buildRequirementRow('Publish content to the platform'),
                      _buildRequirementRow('Create subscription plans'),
                      _buildRequirementRow('Earn from your subscribers'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to subscription/premium screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigate to premium subscription screen'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Subscribe'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking app subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRequirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
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

  void _showCreatorDetails(Map<String, dynamic> creator) {
    final isOwnCreator = _currentUserId == creator['user_id'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreatorDetailsSheet(
        creator: creator,
        isOwnCreator: isOwnCreator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Farmers'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search creators...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
          // Creator Tools Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToCreatorTools,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Creator Tools',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Creators list
          Expanded(
            child: _filteredCreators.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No creators yet'
                              : 'No creators found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCreators.length,
                    itemBuilder: (context, index) {
                      final creator = _filteredCreators[index];
                      return _buildCreatorCard(context, creator);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(BuildContext context, Map<String, dynamic> creator) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile picture and name
            Row(
              children: [
                creator['profile_picture_url'] != null
                    ? CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(
                          creator['profile_picture_url'],
                        ),
                      )
                    : const CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.person),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator['display_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Creator Farmer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bio
            Text(
              creator['bio'] ?? 'No bio provided',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCreatorDetails(creator),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View & Subscribe',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> creator;
  final bool isOwnCreator;

  const _CreatorDetailsSheet({
    Key? key,
    required this.creator,
    required this.isOwnCreator,
  }) : super(key: key);

  @override
  State<_CreatorDetailsSheet> createState() => __CreatorDetailsSheetState();
}

class __CreatorDetailsSheetState extends State<_CreatorDetailsSheet> {
  List<Map<String, dynamic>> _plans = [];
  bool _loadingPlans = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isOwnCreator) {
      _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    try {
      final response = await Supabase.instance.client
          .from('creator_subscription_plans')
          .select()
          .eq('creator_id', widget.creator['user_id'])
          .eq('is_active', true)
          .order('price', ascending: true);

      setState(() {
        _plans = List<Map<String, dynamic>>.from(response);
        _loadingPlans = false;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
      setState(() => _loadingPlans = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator Header
            Row(
              children: [
                widget.creator['profile_picture_url'] != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          widget.creator['profile_picture_url'],
                        ),
                      )
                    : const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.creator['display_name'] ?? 'Unknown',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Creator Farmer',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'About',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.creator['bio'] ?? 'No bio provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Subscription Plans Section (if not own creator)
            if (!widget.isOwnCreator) ...[
              const SizedBox(height: 24),
              Text(
                'Subscribe to this Creator',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_loadingPlans)
                const Center(child: CircularProgressIndicator())
              else if (_plans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No subscription plans available yet',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ..._plans.map((plan) => _buildPlanOption(context, plan)),
            ],

            const SizedBox(height: 24),
            if (widget.isOwnCreator)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'This is Your Creator Profile',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (_plans.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'View all subscription options for ${widget.creator['display_name']}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View All Plans',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, Map<String, dynamic> plan) {
    final name = plan['name'] ?? 'Plan';
    final price = plan['price'] ?? 0;
    final description = plan['description'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionCheckoutScreen(
              creatorId: widget.creator['user_id'],
              plan: plan,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Text(
                  '/month',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}