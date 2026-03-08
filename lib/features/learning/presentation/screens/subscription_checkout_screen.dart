import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionCheckoutScreen extends StatefulWidget {
  final String creatorId;
  final Map<String, dynamic> plan;

  const SubscriptionCheckoutScreen({
    Key? key,
    required this.creatorId,
    required this.plan,
  }) : super(key: key);

  @override
  State<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends State<SubscriptionCheckoutScreen> {
  bool _processing = false;
  Map<String, dynamic>? _creatorProfile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCreatorProfile();
  }

  Future<void> _loadCreatorProfile() async {
    try {
      final response = await Supabase.instance.client
          .from('creator_profiles')
          .select()
          .eq('user_id', widget.creatorId)
          .maybeSingle();

      setState(() {
        _creatorProfile = response;
        _loadingProfile = false;
      });
    } catch (e) {
      debugPrint('Error loading creator profile: $e');
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _handleSubscription() async {
    setState(() => _processing = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get plan ID from the plan data
      final planId = widget.plan['id'];
      if (planId == null) {
        throw Exception('Plan ID not found');
      }

      // Create subscription record in paid_subscriptions table
      final now = DateTime.now();
      await Supabase.instance.client
          .from('paid_subscriptions')
          .insert({
            'subscriber_id': currentUser.id,
            'plan_id': planId,
            'status': 'active',
            'current_period_start': now.toIso8601String().split('T')[0],
            'current_period_end': now.add(const Duration(days: 30)).toIso8601String().split('T')[0],
            'auto_renew': true,
          })
          .select()
          .single();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully subscribed to ${_creatorProfile?['display_name'] ?? 'creator'}!',
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error processing subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.plan['price'] ?? 0;
    final name = widget.plan['name'] ?? 'Subscription';
    final description = widget.plan['description'] ?? '';
    final benefits = widget.plan['benefits'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator Info Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              _creatorProfile?['profile_picture_url'] != null
                                  ? NetworkImage(
                                      _creatorProfile!['profile_picture_url'],
                                    )
                                  : null,
                          child: _creatorProfile?['profile_picture_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _creatorProfile?['display_name'] ?? 'Creator',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You\'ll subscribe to this creator',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plan Details Card
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('/month'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Benefits List
                        if (benefits.isNotEmpty) ...[
                          const Text(
                            'What\'s included:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...benefits.map((benefit) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: AppColors.primaryGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        benefit.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Terms',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Subscription renews automatically every month\n'
                          '• Cancel anytime from your account settings\n'
                          '• You\'ll have immediate access to all benefits\n'
                          '• Charges will appear on your app store receipt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscribe Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processing ? null : _handleSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: _processing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Subscribe for \$${price.toStringAsFixed(2)}/month',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _processing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      child: const Text(
                        'Not Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
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
