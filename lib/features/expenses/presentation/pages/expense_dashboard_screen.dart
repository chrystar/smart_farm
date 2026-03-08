import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm/features/batch/domain/entities/batch.dart';
import 'package:smart_farm/features/batch/presentation/provider/batch_provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../provider/expense_provider.dart';
import '../../domain/entities/expense.dart';
import 'add_expense_screen.dart';
import '../../../settings/presentation/provider/settings_provider.dart';

class ExpenseDashboardScreen extends StatefulWidget {
  const ExpenseDashboardScreen({super.key});

  @override
  State<ExpenseDashboardScreen> createState() => _ExpenseDashboardScreenState();
}

class _ExpenseDashboardScreenState extends State<ExpenseDashboardScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedBatchId;

  String _getCurrencySymbol(String currencyCode) {
    const Map<String, String> currencySymbols = {
      'USD': '\$',
      'NGN': '₦',
      'GHS': '₵',
      'KES': 'KSh',
      'ZAR': 'R',
      'EUR': '€',
      'GBP': '£',
    };
    return currencySymbols[currencyCode] ?? currencyCode;
  }

  NumberFormat _getCurrencyFormat(String currencyCode) {
    return NumberFormat.currency(symbol: _getCurrencySymbol(currencyCode));
  }

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _loadBatches();
    _loadExpenses();
  }

  Future<void> _loadBatches() async {
    final userId = SupabaseService().currentUserId;
    if (userId == null) return;

    await context.read<BatchProvider>().loadBatches(userId);
    if (!mounted) return;

    final batches = context.read<BatchProvider>().batches;
    if (_selectedBatchId == null && batches.isNotEmpty) {
      setState(() {
        _selectedBatchId = batches.first.id;
      });
    }
  }

  Future<void> _loadExpenses() async {
    if (_selectedDateRange != null) {
      await context.read<ExpenseProvider>().loadExpensesByDateRange(
            _selectedDateRange!.start,
            _selectedDateRange!.end,
          );
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Cap the end date to today if needed
    final validDateRange = _selectedDateRange != null && _selectedDateRange!.end.isAfter(today)
        ? DateTimeRange(
            start: _selectedDateRange!.start,
            end: today,
          )
        : _selectedDateRange;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: validDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of( context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expense Analytics'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final currencyCode = context.read<SettingsProvider>().preferences?.defaultCurrency ?? 'USD';
          final batches = context.watch<BatchProvider>().batches;
          final selectedExists = batches.any((batch) => batch.id == _selectedBatchId);
          final selectedBatchValue = selectedExists ? _selectedBatchId : null;
          final filteredExpenses = selectedBatchValue == null
              ? <Expense>[]
              : provider.expenses
                  .where((expense) => expense.batchId == selectedBatchValue)
                  .toList();

          final totalExpenses = filteredExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );
          final categoryBreakdown = _getExpensesByCategory(filteredExpenses);
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExpenses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No batches available'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddExpenseScreen(),
                        ),
                      ).then((_) => _loadExpenses());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create/Add from Batch'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadBatches();
              await _loadExpenses();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Display
                  _buildDateRangeCard(),
                  const SizedBox(height: 16),

                  _buildBatchCardsSection(batches, provider.expenses),
                  const SizedBox(height: 24),

                  if (selectedBatchValue == null)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Select a batch to view expense analysis.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else if (filteredExpenses.isEmpty)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No expenses for selected batch in this period.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else ...[

                  // Summary Cards
                  _buildSummaryCards(totalExpenses, filteredExpenses.length, currencyCode),
               
                  const SizedBox(height: 24),

                  // Category Breakdown List
                  _buildCategoryBreakdownList(categoryBreakdown, totalExpenses, currencyCode),
                  const SizedBox(height: 24),

                  // Trend Chart
                  const Text(
                    'Expense Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTrendChart(filteredExpenses, currencyCode),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final selectedBatch = context
              .read<BatchProvider>()
              .batches
              .where((batch) => batch.id == _selectedBatchId)
              .cast<Batch?>()
              .firstWhere((batch) => batch != null, orElse: () => null);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                initialBatchId: _selectedBatchId,
                initialFolderTitle: selectedBatch?.expenseLogFolderTitle,
              ),
            ),
          ).then((_) => _loadExpenses());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBatchCardsSection(
    List<Batch> batches,
    List<Expense> allPeriodExpenses,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Batch for Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...batches.map((batch) {
          final isSelected = batch.id == _selectedBatchId;
          final batchExpenses =
              allPeriodExpenses.where((e) => e.batchId == batch.id).toList();
          final batchTotal = batchExpenses.fold<double>(0, (sum, e) => sum + e.amount);
          final currency = batchExpenses.isNotEmpty ? batchExpenses.first.currency : '\$';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _selectedBatchId = isSelected ? null : batch.id;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                  ),
                                ),
                                if (batch.breed != null)
                                  Text(
                                    batch.breed!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 1, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBatchInfoItem(
                              icon: Icons.receipt_long,
                              label: 'Expenses',
                              value: '${batchExpenses.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBatchInfoItem(
                              icon: Icons.attach_money,
                              label: 'Total',
                              value: '$currency${batchTotal.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBatchInfoItem({
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
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Map<ExpenseCategory, double> _getExpensesByCategory(List<Expense> expenses) {
    final categoryTotals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Widget _buildDateRangeCard() {
    if (_selectedDateRange == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM dd, yyyy');
    return GestureDetector(
      onTap: _selectDateRange,
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Period',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _selectDateRange,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double total, int count, String currencyCode) {
    final format = _getCurrencyFormat(currencyCode);
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    format.format(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCategoryBreakdownList(
    Map<ExpenseCategory, double> categoryData,
    double total,
    String currencyCode,
  ) {
    final format = _getCurrencyFormat(currencyCode);
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Category Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...sortedEntries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return ListTile(
              leading: CircleAvatar(
                child: Text(entry.key.icon, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(entry.key.displayName),
              subtitle: Text('$percentage% of total'),
              trailing: Text(
                format.format(entry.value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Expense> expenses, String currencyCode) {
    final symbol = _getCurrencySymbol(currencyCode);
    
    if (expenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    // Group expenses by date and sum amounts
    final Map<DateTime, double> dailyTotals = {};
    for (var expense in expenses) {
      final dateOnly = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + expense.amount;
    }

    // Sort by date
    final sortedDates = dailyTotals.keys.toList()..sort();
    
    // Create spots for line chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTotals[sortedDates[i]]!));
    }

    final maxY = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '$symbol${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: sortedDates.length > 7 ? sortedDates.length / 7 : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedDates.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedDates[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: maxY * 1.1,
        ),
      ),
    );
  }
}
