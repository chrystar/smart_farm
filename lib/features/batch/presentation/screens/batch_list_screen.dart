import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';
import '../../domain/entities/batch.dart';
import '../provider/batch_provider.dart';
import 'package:go_router/go_router.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  Timer? _midnightTimer;
  
  String _getCurrencySymbol(String? currency) {
    if (currency == null) return '\$';
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'KES':
        return 'KSh';
      case 'NGN':
        return '₦';
      case 'ZAR':
        return 'R';
      case 'GHS':
        return '₵';
      default:
        return '\$';
    }
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBatches();
      _scheduleMidnightRefresh();
    });
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer?.cancel();
    _midnightTimer = Timer(duration, () {
      if (!mounted) return;
      // Trigger a rebuild so days-since-start recomputes
      setState(() {});
      // Reschedule for the following midnight
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _loadBatches() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId != null) {
      context.read<BatchProvider>().loadBatches(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Batches',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Consumer<BatchProvider>(
        builder: (context, batchProvider, _) {
          if (batchProvider.isLoading && batchProvider.batches.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (batchProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    batchProvider.error!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadBatches,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (batchProvider.batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No batches yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first batch to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadBatches(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusSection(
                  'Planned',
                  batchProvider.getBatchesByStatus(BatchStatus.planned),
                  Colors.blue,
                ),
                const SizedBox(height: 24),
                _buildStatusSection(
                  'Active',
                  batchProvider.getBatchesByStatus(BatchStatus.active),
                  Colors.green,
                ),
                const SizedBox(height: 24),
                _buildStatusSection(
                  'Completed',
                  batchProvider.getBatchesByStatus(BatchStatus.completed),
                  Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 1,
        onPressed: () => context.push('/batches/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildStatusSection(String title, List<Batch> batches, Color color) {
    if (batches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${batches.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...batches.map((batch) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildBatchCard(batch, color),
            )),
      ],
    );
  }

  Widget _buildBatchCard(Batch batch, Color statusColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          context.read<BatchProvider>().setCurrentBatch(batch);
          context.push('/batches/${batch.id}');
        },
        onLongPress: () => _showDeleteDialog(batch),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and bird type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (batch.breed != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            batch.breed!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildBirdTypeChip(batch.birdType),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              
              const SizedBox(height: 16),
              
              // Info grid
              Row(
                children: [
                  // Quantity
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.pets_outlined,
                      label: 'Birds',
                      value: batch.status == BatchStatus.planned
                          ? '${batch.expectedQuantity}'
                          : '${batch.actualQuantity ?? batch.expectedQuantity}',
                    ),
                  ),
                  
                  // Days (if started)
                  if (batch.startDate != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Days',
                        value: '${batch.getDaysSinceStart() ?? 0}',
                      ),
                    ),
                  ],
                  
                  // Purchase cost (if available)
                  if (batch.purchaseCost != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.attach_money,
                        label: 'Cost',
                        value: '${_getCurrencySymbol(batch.currency)}${batch.purchaseCost!.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBirdTypeChip(BirdType type) {
    final isBroiler = type == BirdType.broiler;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBroiler ? Colors.orange[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBroiler ? 'Broiler' : 'Layer',
        style: TextStyle(
          color: isBroiler ? Colors.orange[700] : Colors.purple[700],
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // Removed unused _buildInfoChip helper to satisfy analyzer

  void _showDeleteDialog(Batch batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: Text(
          'Are you sure you want to delete "${batch.name}"?\n\nThis will also delete all daily records associated with this batch. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await context.read<BatchProvider>().deleteBatch(batch.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${batch.name} deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                final error = context.read<BatchProvider>().error;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Failed to delete batch'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
