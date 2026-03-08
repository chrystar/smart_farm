import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import '../../domain/entities/sale.dart';
import '../provider/sales_provider.dart';
import '../../data/services/profit_margin_service.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../batch/domain/entities/batch.dart';
import '../../../batch/presentation/provider/batch_provider.dart';
import '../../../expenses/presentation/provider/expense_provider.dart';
import '../../../authentication/presentation/provider/auth_provider.dart';

class ProfitMarginAnalysisScreen extends StatefulWidget {
  final String? batchId;

  const ProfitMarginAnalysisScreen({
    Key? key,
    this.batchId,
  }) : super(key: key);

  @override
  State<ProfitMarginAnalysisScreen> createState() =>
      _ProfitMarginAnalysisScreenState();
}

class _ProfitMarginAnalysisScreenState
    extends State<ProfitMarginAnalysisScreen> {
  late ProfitAnalysis _analysis;
  bool _loading = true;
  String? _selectedBatchId;
  String _expenseFilterOption = 'all'; // 'all' or the label string

  @override
  void initState() {
    super.initState();
    _selectedBatchId = widget.batchId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalysis();
    });
  }

  void _loadAnalysis() {
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final authProvider = context.read<AuthProvider>();

      final expenses = expenseProvider.expenses;

      // If expenses list is empty, fetch from Supabase
      if (expenses.isEmpty && authProvider.user != null) {
        expenseProvider.loadExpenses(authProvider.user!.id).then((_) {
          // Reload analysis after expenses are loaded
          _loadAnalysisAfterFetch();
        });
        return;
      }

      _loadAnalysisAfterFetch();
    } catch (e) {
      print('Error loading analysis: $e');
      setState(() => _loading = false);
    }
  }

  void _loadAnalysisAfterFetch() {
    try {
      final batchProvider = context.read<BatchProvider>();
      final salesProvider = context.read<SalesProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final batches = batchProvider.batches;
      final sales = salesProvider.sales;
      final expenses = expenseProvider.expenses;

      print('=== PROFIT ANALYSIS DEBUG ===');
      print('Total batches: ${batches.length}');
      print('Total sales: ${sales.length}');
      print('Total expenses: ${expenses.length}');
      if (expenses.isNotEmpty) {
        print(
            'First expense: ${expenses.first.category} - \$${expenses.first.amount} - batchId: ${expenses.first.batchId}');
      }

      if (batches.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      if (_selectedBatchId == null) {
        setState(() => _loading = false);
        return;
      }

      // Find selected batch from provided context
      late Batch selectedBatch;
      try {
        selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);
      } catch (e) {
        setState(() => _loading = false);
        return;
      }

      final batchSales =
          sales.where((s) => s.batchId == selectedBatch.id).toList();
      var batchExpenses =
          expenses.where((e) => e.batchId == selectedBatch.id).toList();

      print('Selected batch: ${selectedBatch.name} (${selectedBatch.id})');
      print('Sales for this batch: ${batchSales.length}');
      print('Expenses linked to this batch: ${batchExpenses.length}');

      // Load daily records to get mortality data
      batchProvider.loadDailyRecords(selectedBatch.id);
      debugPrint('✅ DEBUG: Called loadDailyRecords for batch ${selectedBatch.id}');

      setState(() {
        _analysis = ProfitMarginService.analyzeBatch(
          batch: selectedBatch,
          batchSales: batchSales,
          batchExpenses: batchExpenses,
        );
        _loading = false;
      });
    } catch (e) {
      print('Error in _loadAnalysisAfterFetch: $e');
      setState(() => _loading = false);
    }
  }

  void _recalculateAnalysisForSelectedExpenses() {
    try {
      final batchProvider = context.read<BatchProvider>();
      final salesProvider = context.read<SalesProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final batches = batchProvider.batches;
      final sales = salesProvider.sales;
      final expenses = expenseProvider.expenses;

      if (batches.isEmpty || _selectedBatchId == null) return;

      // Find the selected batch
      late Batch selectedBatch;
      try {
        selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);
      } catch (e) {
        return;
      }

      final batchSales =
          sales.where((s) => s.batchId == selectedBatch.id).toList();
      var batchExpenses =
          expenses.where((e) => e.batchId == selectedBatch.id).toList();

      // Filter expenses based on selected group
      if (_expenseFilterOption != 'all') {
        batchExpenses = batchExpenses
            .where((e) => e.groupTitle == _expenseFilterOption)
            .toList();
      }

      setState(() {
        _analysis = ProfitMarginService.analyzeBatch(
          batch: selectedBatch,
          batchSales: batchSales,
          batchExpenses: batchExpenses,
        );
      });
    } catch (e) {
      print('Error in _recalculateAnalysisForSelectedExpenses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Analysis'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysis,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_selectedBatchId == null || !_hasAnalysis())
              ? _buildNoDataState()
              : _buildContent(),
    );
  }

  bool _hasAnalysis() {
    try {
      return _analysis.batchId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No linked batch context found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open this screen from a selected batch in Sales Analysis.',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async => _loadAnalysis(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfitSummary(),
              const SizedBox(height: 24),
              _buildKeyMetrics(),
              const SizedBox(height: 24),
              _buildCurrentBatchStatus(),
              const SizedBox(height: 24),
              _buildCostPerUnitBreakdown(),
              const SizedBox(height: 24),
              _buildBreakEvenAnalysis(),
              const SizedBox(height: 24),
              _buildProfitTimeline(),
              const SizedBox(height: 24),
              _buildProfitByType(),
              const SizedBox(height: 24),
              _buildExpenseBreakdown(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBatchStatus() {
    final batchProvider = context.read<BatchProvider>();
    final batches = batchProvider.batches;

    if (_selectedBatchId == null) {
      return const SizedBox.shrink();
    }

    late Batch selectedBatch;
    try {
      selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);
    } catch (e) {
      return const SizedBox.shrink();
    }

    // Get total mortality for this batch
    final totalMortality = batchProvider.totalMortality;
    debugPrint('🔍 DEBUG: Batch ${selectedBatch.id} - Total Mortality: $totalMortality');
    
    // Use actualQuantity (birds actually received) or fallback to expectedQuantity
    final birdsReceived = selectedBatch.actualQuantity ?? selectedBatch.expectedQuantity;
    final remainingBirds = birdsReceived - totalMortality;
    final birdsSold = _analysis.profitByType.values
        .fold<int>(0, (sum, type) => sum + type.quantitySold);
    final birdsStillInBatch = remainingBirds - birdsSold;

    // Calculate current cost per bird (based on remaining birds)
    final currentCostPerBird = remainingBirds > 0
        ? _analysis.totalCost / remainingBirds
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Batch Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                title: 'Current Cost/Bird',
                value: NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(currentCostPerBird),
                subtitle: 'Based on ${remainingBirds} remaining birds',
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                title: 'Birds Still in Batch',
                value: birdsStillInBatch.toString(),
                subtitle: '${remainingBirds - birdsSold} not yet sold',
                icon: Icons.pets,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mortality Impact:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    totalMortality > 0
                        ? '${totalMortality} birds died (${((totalMortality / birdsReceived) * 100).toStringAsFixed(1)}%)'
                        : 'No mortality recorded',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: totalMortality > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Original Cost/Bird:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                        .format(_analysis.costPerUnit),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (totalMortality > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cost Increase per Bird:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(currentCostPerBird - _analysis.costPerUnit),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitSummary() {
    final status =
        ProfitMarginService.getProfitStatusLabel(_analysis.profitMargin);
    final isProfit = _analysis.netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit
            ? AppColors.primaryGreen.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: isProfit ? AppColors.primaryGreen : Colors.red,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning if total cost is 0
          if (_analysis.totalCost == 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No expenses recorded for this batch. Add expenses to get accurate profit calculations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Profit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(_analysis.netProfit),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? AppColors.primaryGreen : Colors.red,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_analysis.profitMargin.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Revenue',
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(_analysis.totalRevenue),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  'Cost',
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(_analysis.totalCost),
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Profit Margin',
                '${_analysis.profitMargin.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'ROI',
                '${_analysis.roi.toStringAsFixed(1)}%',
                Icons.assessment,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Cost/Unit',
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(_analysis.costPerUnit),
                Icons.shopping_cart,
                Colors.orange,
                description:
                    'Average cost to raise one bird\n(Total costs ÷ Total birds)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Revenue/Unit',
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(_analysis.revenuePerUnit),
                Icons.attach_money,
                Colors.green,
                description:
                    'Average revenue per bird sold\n(Total sales ÷ Total birds sold)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostPerUnitBreakdown() {
    // Get total birds raised from the batch
    final batchProvider = context.read<BatchProvider>();
    final batches = batchProvider.batches;
    
    int totalBirdsRaised = 0;
    if (_selectedBatchId != null) {
      try {
        final selectedBatch = batches.firstWhere((b) => b.id == _selectedBatchId);
        // Use actualQuantity (birds actually received) or fallback to expectedQuantity
        totalBirdsRaised = selectedBatch.actualQuantity ?? selectedBatch.expectedQuantity;
      } catch (e) {
        totalBirdsRaised = 0;
      }
    }

    // Get grouped expenses for selected batch only
    final expenseProvider = context.read<ExpenseProvider>();
    final groupedExpenses = <String?, List<Expense>>{};
    if (_selectedBatchId != null) {
      final batchExpenses = expenseProvider.expenses
          .where((expense) => expense.batchId == _selectedBatchId)
          .toList();
      for (final expense in batchExpenses) {
        groupedExpenses.putIfAbsent(expense.groupTitle, () => []).add(expense);
      }
    }

    // Calculate total cost per group
    final groupCosts = <String?, double>{};
    for (var entry in groupedExpenses.entries) {
      final groupTotal = entry.value.fold<double>(0, (sum, exp) => sum + exp.amount);
      groupCosts[entry.key] = groupTotal;
    }

    // Filter expenses based on selected option
    late Map<String?, double> filteredGroupCosts;
    late double filteredTotalCost;

    if (_expenseFilterOption == 'all') {
      filteredGroupCosts = groupCosts;
      filteredTotalCost =
          groupCosts.values.fold<double>(0, (sum, cost) => sum + cost);
    } else {
      filteredGroupCosts = {_expenseFilterOption: groupCosts[_expenseFilterOption] ?? 0.0};
      filteredTotalCost = groupCosts[_expenseFilterOption] ?? 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost per Unit Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Cost/Unit:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(_analysis.costPerUnit),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter dropdown
                Text(
                  'View Expenses:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _expenseFilterOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Expenses'),
                      ),
                      ...groupedExpenses.keys.map((groupTitle) {
                        return DropdownMenuItem(
                          value: groupTitle,
                          child: Text(groupTitle ?? 'Ungrouped Expenses'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _expenseFilterOption = value;
                        });
                        _recalculateAnalysisForSelectedExpenses();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _expenseFilterOption == 'all'
                      ? 'Breakdown by Expense Group:'
                      : 'Details for $_expenseFilterOption:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // Display filtered expenses
                if (filteredGroupCosts.isEmpty)
                  Text(
                    'No expenses in this group',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...filteredGroupCosts.entries.map((entry) {
                    final groupTitle = entry.key ?? 'Ungrouped';
                    final amount = entry.value;
                    final costPerUnitForGroup =
                        totalBirdsRaised > 0 ? amount / totalBirdsRaised : 0.0;
                    final percentage = filteredTotalCost > 0
                        ? (amount / filteredTotalCost) * 100
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  groupTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 2,
                                ).format(costPerUnitForGroup),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCategoryColor(groupTitle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(1)}% of selected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(amount),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String label) {
    switch (label.toLowerCase()) {
      case 'feed':
        return const Color(0xFF8B7355); // Brown
      case 'chicks/birds':
        return const Color(0xFFFF9800); // Orange
      case 'medicine & vaccines':
        return const Color(0xFF2196F3); // Blue
      case 'equipment':
        return const Color(0xFF9C27B0); // Purple
      case 'utilities':
        return const Color(0xFFFFC107); // Amber
      case 'labor':
        return const Color(0xFF4CAF50); // Green
      case 'transportation':
        return const Color(0xFFF44336); // Red
      case 'maintenance':
        return const Color(0xFF00BCD4); // Cyan
      case 'marketing':
        return const Color(0xFFE91E63); // Pink
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  Widget _buildBreakEvenAnalysis() {
    final beQuantity = _analysis.breakEvenQuantity;
    final beDate = _analysis.breakEvenDate;
    final daysToBreakEven =
        beDate != null && _analysis.profitTimeline.isNotEmpty
            ? beDate.difference(_analysis.profitTimeline.first.date).inDays
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Break-Even Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Break-Even Quantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$beQuantity units',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    if (beDate != null && daysToBreakEven != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Days to Break-Even',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$daysToBreakEven days',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (beDate != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Break-Even Date',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(beDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitTimeline() {
    if (_analysis.profitTimeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profit Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (_analysis.profitTimeline.length / 5)
                            .ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _analysis.profitTimeline.length) {
                            return Text(
                              '${value.toInt() + 1}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: (_analysis.profitTimeline.length - 1).toDouble(),
                  minY: _analysis.profitTimeline
                          .map((p) => p.cumulativeProfit)
                          .reduce((a, b) => a < b ? a : b) *
                      1.1,
                  maxY: _analysis.profitTimeline
                          .map((p) => p.cumulativeProfit)
                          .reduce((a, b) => a > b ? a : b) *
                      1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _analysis.profitTimeline
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(),
                              entry.value.cumulativeProfit))
                          .toList(),
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _analysis.profitTimeline.length < 15,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfitByType() {
    if (_analysis.profitByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profit by Sale Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analysis.profitByType.values.map((typeAnalysis) {
                final color = _getSaleTypeColor(typeAnalysis.saleType);
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getSaleTypeIcon(typeAnalysis.saleType),
                        color: color,
                      ),
                      title: Text(typeAnalysis.saleType.displayName),
                      subtitle: Text(
                        '${typeAnalysis.quantitySold} units • ${typeAnalysis.profitMargin.toStringAsFixed(1)}% margin',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            ).format(typeAnalysis.grossProfit),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            'Profit',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdown() {
    if (_analysis.expenseBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analysis.expenseBreakdown.map((expense) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            expense.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 0)
                                .format(expense.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: expense.percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: AppColors.primaryGreen,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${expense.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSaleTypeIcon(SaleType type) {
    switch (type) {
      case SaleType.birds:
        return Icons.egg;
      case SaleType.eggs:
        return Icons.egg_outlined;
      case SaleType.manure:
        return Icons.compost;
      case SaleType.other:
        return Icons.shopping_basket;
    }
  }

  Color _getSaleTypeColor(SaleType type) {
    switch (type) {
      case SaleType.birds:
        return Colors.brown;
      case SaleType.eggs:
        return Colors.orange;
      case SaleType.manure:
        return Colors.green;
      case SaleType.other:
        return Colors.purple;
    }
  }
}
