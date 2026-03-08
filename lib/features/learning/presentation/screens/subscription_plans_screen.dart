import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('creator_subscription_plans')
          .select()
          .eq('creator_id', user.id)
          .order('price', ascending: true);

      setState(() {
        _plans = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _addPlan() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreatePlanDialog(),
    );

    if (result != null) {
      _savePlan(result);
    }
  }

  Future<void> _savePlan(Map<String, dynamic> planData) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      const uuid = Uuid();
      await Supabase.instance.client.from('creator_subscription_plans').insert({
        'id': uuid.v4(),
        'creator_id': user.id,
        'name': planData['name'],
        'description': planData['description'],
        'price': double.parse(planData['price'].toString()),
        'currency': 'USD',
        'benefits': planData['benefits'] as List<String>,
        'is_active': true,
      });

      _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription plan created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlan(String planId) async {
    try {
      await Supabase.instance.client
          .from('creator_subscription_plans')
          .delete()
          .eq('id', planId);

      _loadPlans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Subscription Plans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create subscription tiers for your subscribers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addPlan,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Plan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _plans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_membership,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No subscription plans yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Create a plan to start earning from subscribers',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            final plan = _plans[index];
                            return _buildPlanCard(plan);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] ?? 'Plan';
    final description = plan['description'] ?? '';
    final price = plan['price'] ?? 0;
    final benefits = plan['benefits'] as List<dynamic>? ?? [];
    final isActive = plan['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppColors.primaryGreen : Colors.grey,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(plan['id']);
                    } else if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit plan coming soon'),
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
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Text('/month'),
              ],
            ),
            const SizedBox(height: 12),
            if (benefits.isNotEmpty) ...[
              const Text(
                'Benefits:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
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
                            benefit.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text(
          'Are you sure you want to delete this plan? Existing subscriptions will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlan(planId);
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
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog({Key? key}) : super(key: key);

  @override
  State<_CreatePlanDialog> createState() => __CreatePlanDialogState();
}

class __CreatePlanDialogState extends State<_CreatePlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _benefitsController = TextEditingController();
  final List<String> _benefits = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _addBenefit() {
    if (_benefitsController.text.isNotEmpty) {
      setState(() {
        _benefits.add(_benefitsController.text);
        _benefitsController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Subscription Plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'e.g., Basic, Premium, VIP',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Plan name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What does this plan offer?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Price (\$)',
                  hintText: '4.99',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _benefitsController,
                      decoration: const InputDecoration(
                        labelText: 'Add Benefit',
                        hintText: 'e.g., Early access',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addBenefit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              if (_benefits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _benefits
                      .map((benefit) => Chip(
                            label: Text(benefit),
                            onDeleted: () {
                              setState(() => _benefits.remove(benefit));
                            },
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'price': _priceController.text,
                'benefits': _benefits,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
