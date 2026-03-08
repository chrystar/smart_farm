import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:smart_farm/features/batch/presentation/provider/batch_provider.dart';
import 'package:smart_farm/features/batch/domain/entities/batch.dart';
import 'package:smart_farm/features/sales/presentation/pages/record_sale_screen.dart';
import 'package:smart_farm/features/sales/presentation/pages/sales_analysis_screen.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/sale.dart';
import '../provider/sales_provider.dart';
import '../../data/services/sales_export_service.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  PaymentStatus? _selectedPaymentFilter;
  String? _selectedBatchId;
  bool _isSelectionMode = false;
  final Set<String> _selectedSaleIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSales();
    });
  }

  void _loadSales() {
    final userId = SupabaseService().currentUserId;
    if (userId != null) {
      context.read<SalesProvider>().loadSales(userId);
      context.read<BatchProvider>().loadBatches(userId).then((_) {
        if (!mounted) return;
        if (_selectedBatchId == null) {
          final batches = context.read<BatchProvider>().batches;
          if (batches.isNotEmpty) {
            setState(() {
              _selectedBatchId = batches.first.id;
            });
          }
        }
      });
    }
  }

  Future<void> _updatePaymentStatus(Sale sale, PaymentStatus status) async {
    final provider = context.read<SalesProvider>();
    final success = await provider.updatePaymentStatus(sale.id, status);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Payment status updated' : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSale(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: const Text('Are you sure you want to delete this sale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SalesProvider>();
      final success = await provider.deleteSale(sale.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Sale deleted' : 'Failed to delete sale',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSaleIds.clear();
      }
    });
  }

  Future<void> _showAddSaleDialog(BuildContext context) async {
    final userId = SupabaseService().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Load batches
    final batchProvider = context.read<BatchProvider>();
    await batchProvider.loadBatches(userId);

    final batches = batchProvider.batches;

    if (!mounted) return;

    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No batches available. Create a batch first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedBatchId != null) {
      try {
        final selectedBatch =
            batches.firstWhere((batch) => batch.id == _selectedBatchId);
        _openRecordSaleScreen(selectedBatch.id, selectedBatch.name);
      } catch (_) {
        _openRecordSaleScreen(batches.first.id, batches.first.name);
      }
      return;
    }

    // Show batch selection dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Batch'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                return ListTile(
                  title: Text(batch.name),
                  subtitle: Text(
                      '${batch.status.toString()} • ${batch.actualQuantity ?? 0} birds'),
                  onTap: () {
                    Navigator.pop(context);
                    _openRecordSaleScreen(batch.id, batch.name);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRecordSaleScreen(String batchId, String batchName) async {
    final saleResult = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordSaleScreen(
          batchId: batchId,
          batchName: batchName,
        ),
      ),
    );

    if (saleResult != null && mounted) {
      _loadSales();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleSaleSelection(String saleId) {
    setState(() {
      if (_selectedSaleIds.contains(saleId)) {
        _selectedSaleIds.remove(saleId);
      } else {
        _selectedSaleIds.add(saleId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_selectedSaleIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 sales to group'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final groupTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedSaleIds.length} sales selected',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Group Title',
                  hintText: 'e.g., Week 1 Sales, January Batch',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a group title'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (groupTitle != null && mounted) {
      final provider = context.read<SalesProvider>();
      final success = await provider.createSaleGroup(
        groupTitle,
        _selectedSaleIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Group "$groupTitle" created successfully'
                  : 'Failed to create group',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) {
          setState(() {
            _isSelectionMode = false;
            _selectedSaleIds.clear();
          });
          _loadSales();
        }
      }
    }
  }

  void _showPendingPaymentsDialog() {
    final provider = context.read<SalesProvider>();
    final pendingSales = provider.sales
        .where((s) => s.batchId == _selectedBatchId && s.paymentStatus == PaymentStatus.pending)
        .toList();

    if (pendingSales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending payments for this batch'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedForPayment = <String>{};
            
            return AlertDialog(
              title: Text('Mark Payments as Paid (${pendingSales.length})'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: pendingSales.length,
                  itemBuilder: (context, index) {
                    final sale = pendingSales[index];
                    final isSelected = selectedForPayment.contains(sale.id);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selectedForPayment.add(sale.id);
                          } else {
                            selectedForPayment.remove(sale.id);
                          }
                        });
                      },
                      title: Text(sale.saleType.displayName),
                      subtitle: Text(
                        '${sale.currency} ${sale.totalAmount.toStringAsFixed(2)} • ${DateFormat('MMM dd').format(sale.saleDate)}',
                      ),
                      secondary: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${sale.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'qty',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      if (selectedForPayment.length == pendingSales.length) {
                        selectedForPayment.clear();
                      } else {
                        selectedForPayment.addAll(pendingSales.map((s) => s.id));
                      }
                    });
                  },
                  child: Text(
                    selectedForPayment.length == pendingSales.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedForPayment.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _markSelectedAsPaid(selectedForPayment.toList());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Mark ${selectedForPayment.length} as Paid'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markSelectedAsPaid(List<String> saleIds) async {
    final provider = context.read<SalesProvider>();
    int successCount = 0;
    
    for (final saleId in saleIds) {
      final success = await provider.updatePaymentStatus(saleId, PaymentStatus.paid);
      if (success) successCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount of ${saleIds.length} payments marked as paid'),
          backgroundColor: successCount == saleIds.length ? Colors.green : Colors.orange,
        ),
      );
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isSelectionMode ? '${_selectedSaleIds.length} selected' : 'Sales'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      final provider = context.read<SalesProvider>();
                      if (_selectedSaleIds.length == provider.sales.length) {
                        _selectedSaleIds.clear();
                      } else {
                        _selectedSaleIds.addAll(
                          provider.sales.map((s) => s.id),
                        );
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: _createGroup,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: () => _showExportMenu(context),
                  tooltip: 'Export',
                ),
                IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesAnalysisScreen(),
                      ),
                    );
                  },
                  tooltip: 'Sales Analysis',
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddSaleDialog(context),
                ),
              ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSales,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

            final batches = context.watch<BatchProvider>().batches;
            final selectedExists =
                batches.any((batch) => batch.id == _selectedBatchId);
            final selectedBatchValue = selectedExists ? _selectedBatchId : null;

            final filteredSales = _selectedPaymentFilter == null
                ? provider.sales
                : provider.sales
                    .where((s) => s.paymentStatus == _selectedPaymentFilter)
                    .toList();

            final folderFilteredSales = selectedBatchValue == null
                ? filteredSales
                : filteredSales.where((s) => s.batchId == selectedBatchValue).toList();

          return Column(
            children: [
              // Batch Cards Section
              Expanded(
                child: batches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No Batches Yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a batch first to record sales',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...batches.map((batch) {
                            final isSelected = batch.id == _selectedBatchId;
                            final batchSales = folderFilteredSales
                                .where((s) => s.batchId == batch.id)
                                .toList();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildBatchCardWithSales(
                                batch,
                                batchSales,
                                isSelected,
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedBatchId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showPendingPaymentsDialog(),
              icon: const Icon(Icons.payment),
              label: const Text('Mark Paid'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildGroupedSalesList(List<Sale> sales) {
    // Group sales by groupTitle
    final Map<String?, List<Sale>> grouped = {};
    for (var sale in sales) {
      grouped.putIfAbsent(sale.groupTitle, () => []).add(sale);
    }

    // Separate grouped and ungrouped sales
    final ungroupedSales = grouped[null] ?? [];
    final groupedEntries = grouped.entries
        .where((entry) => entry.key != null)
        .toList()
      ..sort(
          (a, b) => b.value.first.saleDate.compareTo(a.value.first.saleDate));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Display groups first
        ...groupedEntries.map((entry) {
          final groupTitle = entry.key!;
          final groupSales = entry.value;
          final totalAmount = groupSales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalAmount,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Header
              Container(
                margin: const EdgeInsets.only(bottom: 8, top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${groupSales.length} sales · ${groupSales.first.currency} ${totalAmount.toStringAsFixed(2)}',
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
              // Group Sales
              ...groupSales.map((sale) {
                final isSelected = _selectedSaleIds.contains(sale.id);
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildSaleCard(sale, isSelected),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }),

        // Display ungrouped sales
        if (ungroupedSales.isNotEmpty) ...[
          if (groupedEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Ungrouped Sales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ...ungroupedSales.map((sale) {
            final isSelected = _selectedSaleIds.contains(sale.id);
            return _buildSaleCard(sale, isSelected);
          }),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale, bool isSelected) {
    final statusColor = _getStatusColor(sale.paymentStatus);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSaleSelection(sale.id);
        } else {
          _showSaleDetails(sale);
        }
        print(' Tapped on sale ${sale.id}');
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedSaleIds.add(sale.id);
          });
        }
        print('Long pressed on sale ${sale.id}');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Leading
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSaleSelection(sale.id),
                )
              else
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    sale.saleType == SaleType.birds
                        ? Icons.restaurant
                        : sale.saleType == SaleType.eggs
                            ? Icons.egg_outlined
                            : Icons.inventory_2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sale.quantity} × ${sale.saleType.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(sale.saleDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sale.paymentStatus.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${sale.currency} ${sale.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (sale.buyerName != null)
                    Text(
                      sale.buyerName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sale.saleType.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(sale.paymentStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.paymentStatus.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(sale.paymentStatus),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Quantity', '${sale.quantity}'),
              _buildDetailRow(
                'Price Per Unit',
                '${sale.currency} ${sale.pricePerUnit.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Total Amount',
                '${sale.currency} ${sale.totalAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Sale Date',
                DateFormat('MMM dd, yyyy').format(sale.saleDate),
              ),
              if (sale.buyerName != null)
                _buildDetailRow('Buyer', sale.buyerName!),
              if (sale.notes != null) _buildDetailRow('Notes', sale.notes!),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              // Payment Status Dropdown
              const Text(
                'Change Payment Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentStatus.values
                    .map((status) => ChoiceChip(
                          label: Text(status.displayName),
                          selected: sale.paymentStatus == status,
                          onSelected: (selected) {
                            if (selected) {
                              _updatePaymentStatus(sale, status);
                              Navigator.pop(context);
                            }
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSale(sale);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.partiallyPaid:
        return Colors.blue;
    }
  }

  void _showExportMenu(BuildContext context) {
    final provider = context.read<SalesProvider>();
    final sales = _selectedPaymentFilter == null
        ? provider.sales
        : provider.sales
            .where((s) => s.paymentStatus == _selectedPaymentFilter)
            .toList();

    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sales data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.file_download, color: Colors.green),
                    const SizedBox(width: 12),
                    const Text(
                      'Export Sales Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF Report'),
                subtitle: Text('${sales.length} sales with summary'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _exportPDF(sales);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export as CSV'),
                subtitle: Text('${sales.length} sales in spreadsheet format'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _exportCSV(sales);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share PDF Report'),
                subtitle: const Text('Share via email, WhatsApp, etc.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _sharePDF(sales);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Share CSV Data'),
                subtitle: const Text('Share spreadsheet file'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _shareCSV(sales);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPDF(List<Sale> sales) async {
    try {
      final file = await SalesExportService.exportToPDF(
        sales,
        title: 'Sales Report',
        startDate: sales.isNotEmpty
            ? sales
                .map((s) => s.saleDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now(),
        endDate: sales.isNotEmpty
            ? sales
                .map((s) => s.saleDate)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _sharePDF(sales),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportCSV(List<Sale> sales) async {
    try {
      final file = await SalesExportService.exportToCSV(sales);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareCSV(sales),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePDF(List<Sale> sales) async {
    try {
      await SalesExportService.exportAndSharePDF(
        sales,
        title: 'Sales Report',
        startDate: sales.isNotEmpty
            ? sales
                .map((s) => s.saleDate)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : DateTime.now(),
        endDate: sales.isNotEmpty
            ? sales
                .map((s) => s.saleDate)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareCSV(List<Sale> sales) async {
    try {
      await SalesExportService.exportAndShareCSV(sales);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBatchCardWithSales(
    Batch batch,
    List<Sale> batchSales,
    bool isSelected,
  ) {
    final totalAmount = batchSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final pendingCount = batchSales.where((s) => s.paymentStatus == PaymentStatus.pending).length;
    final currency = batchSales.isNotEmpty ? batchSales.first.currency : '\$';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedBatchId = _selectedBatchId == batch.id ? null : batch.id;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with batch name
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
                                fontSize: 18,
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isSelected ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  const SizedBox(height: 12),
                  // Sales summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Sales',
                          value: '${batchSales.length}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.schedule,
                          label: 'Pending',
                          value: '$pendingCount',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.attach_money,
                          label: 'Total',
                          value: '$currency${totalAmount.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded sales list
          if (isSelected && batchSales.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: batchSales.length,
                    itemBuilder: (context, index) {
                      final sale = batchSales[index];
                      final isSaleSelected = _selectedSaleIds.contains(sale.id);
                      return _buildSaleCard(sale, isSaleSelected);
                    },
                  ),
                ],
              ),
            ),
          if (isSelected && batchSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No sales yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
          ),
        ),
      ],
    );
  }
}
