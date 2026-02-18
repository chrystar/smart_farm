import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/batch/domain/entities/batch.dart';
import 'package:smart_farm/features/batch/presentation/provider/batch_provider.dart';
import 'package:smart_farm/features/sales/presentation/pages/record_sale_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:intl/intl.dart';
import '../../../vaccination/presentation/widgets/vaccination_tab_widget.dart';
import '../../../vaccination/data/datasources/vaccination_remote_datasource.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBatchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBatchData() {
    final provider = context.read<BatchProvider>();
    provider.loadDailyRecords(widget.batchId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Batch Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Vaccinations'),
          ],
        ),
      ),
      body: Consumer<BatchProvider>(
        builder: (context, batchProvider, _) {
          final batch = batchProvider.currentBatch;

          if (batch == null) {
            return const Center(child: Text('Batch not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(batch, batchProvider),
              VaccinationTabWidget(
                batchId: batch.id,
                batchName: batch.name,
                batchStartDate: batch.startDate,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Batch batch, BatchProvider batchProvider) {
    return RefreshIndicator(
      onRefresh: () async => _loadBatchData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewCard(batch, batchProvider),
          const SizedBox(height: 16),
          if (batch.status == BatchStatus.planned)
            _buildStartBatchCard(batch),
          if (batch.status == BatchStatus.active) ...[
            _buildAddRecordCard(),
            const SizedBox(height: 16),
            _buildActivateSalesEntryCard(batch),
            const SizedBox(height: 16),
            _buildDailyRecordsSection(batchProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Batch batch, BatchProvider batchProvider) {
    final statusColor = _getStatusColor(batch.status);

    return Card(
      elevation: 0,
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    batch.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(batch.status, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            _buildBirdTypeRow(batch),
            const Divider(height: 32),
            if (batch.status == BatchStatus.planned)
              _buildPlannedInfo(batch)
            else
              _buildActiveInfo(batch, batchProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildBirdTypeRow(Batch batch) {
    final isBroiler = batch.birdType == BirdType.broiler;
    return Row(
      children: [
        Icon(
          isBroiler ? Icons.restaurant : Icons.egg_outlined,
          color: isBroiler ? Colors.orange[700] : Colors.purple[700],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          isBroiler ? 'Broiler' : 'Layer',
          style: TextStyle(
            color: isBroiler ? Colors.orange[700] : Colors.purple[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        if (batch.breed != null) ...[
          const SizedBox(width: 8),
          Text('•', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(width: 8),
          Text(
            batch.breed!,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildPlannedInfo(Batch batch) {
    return Column(
      children: [
        _buildInfoRow(
          'Expected Quantity',
          '${batch.expectedQuantity} birds',
          Icons.numbers,
        ),
        if (batch.purchaseCost != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            'Purchase Cost',
            '${_getCurrencySymbol(batch.currency)}${batch.purchaseCost!.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ],
      ],
    );
  }

  Widget _buildActiveInfo(Batch batch, BatchProvider batchProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Initial',
                '${batch.actualQuantity ?? batch.expectedQuantity}',
                Icons.system_update_alt,
                Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Live Birds',
                '${batchProvider.currentLiveBirds}',
                Icons.pets,
                Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Mortality',
                '${batchProvider.totalMortality}',
                Icons.trending_down,
                Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Days',
                '${batch.getDaysSinceStart() ?? 0}',
                Icons.calendar_today,
                Colors.black,
              ),
            ),
          ],
        ),
        if (batch.startDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Started: ${DateFormat('MMM d, yyyy').format(batch.startDate!)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BatchStatus status, Color color) {
    String label;
    switch (status) {
      case BatchStatus.planned:
        label = 'Planned';
        break;
      case BatchStatus.active:
        label = 'Active';
        break;
      case BatchStatus.completed:
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStartBatchCard(Batch batch) {
    return Card(
      elevation: 0,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_outline,
                    color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Ready to Start',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Chickens arrived? Start this batch to begin daily tracking.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showStartBatchDialog(batch),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Batch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecordCard() {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue[100]!),
      ),
      child: InkWell(
        onTap: _showAddRecordDialog,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Daily Record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Record today\'s mortality and notes',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivateSalesEntryCard(Batch batch) {
    return Card(
      elevation: 0,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber[100]!),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => RecordSaleScreen(
                batchId: batch.id,
                batchName: batch.name,
              ),
            ),
          );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sale recorded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activate Sales Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ready to sell? Record a sale now',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRecordsSection(BatchProvider batchProvider) {
    if (batchProvider.dailyRecords.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No daily records yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...batchProvider.dailyRecords.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, yyyy').format(record.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: record.mortalityCount > 0
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_down,
                                size: 14,
                                color: record.mortalityCount > 0
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${record.mortalityCount}',
                                style: TextStyle(
                                  color: record.mortalityCount > 0
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.notes!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Colors.blue;
      case BatchStatus.active:
        return Colors.green;
      case BatchStatus.completed:
        return Colors.grey;
    }
  }

  void _showStartBatchDialog(Batch batch) {
    final quantityController =
        TextEditingController(text: batch.expectedQuantity.toString());
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Start Batch'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm the details to activate this batch',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Actual Quantity Received',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context);

                final success =
                    await context.read<BatchProvider>().startBatch(
                          batchId: batch.id,
                          actualQuantity: int.parse(quantityController.text),
                          startDate: selectedDate,
                        );

                if (success && mounted) {
                  // Create vaccination schedules for the batch
                  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  final vaccinationDataSource = VaccinationRemoteDataSourceImpl(
                    supabaseClient: Supabase.instance.client,
                  );
                  
                  try {
                    await vaccinationDataSource.createSchedulesForBatch(batch.id, userId);
                  } catch (e) {
                    debugPrint('Failed to create vaccination schedules: $e');
                  }
                  
                  _loadBatchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Batch started successfully with vaccination schedule'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecordDialog() {
    final mortalityController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Daily Record'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: context
                                .read<BatchProvider>()
                                .currentBatch
                                ?.startDate ??
                            DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child:
                          Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: mortalityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Mortality Count',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.trending_down),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 0) {
                        return 'Invalid count';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_outlined),
                      hintText: 'Any observations or notes',
                    ),
                  ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context);

                final success =
                    await context.read<BatchProvider>().createDailyRecord(
                          batchId: widget.batchId,
                          date: selectedDate,
                          mortalityCount: int.parse(mortalityController.text),
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                        );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Record added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  final error = context.read<BatchProvider>().error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to add record'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Show merge dialog
}
