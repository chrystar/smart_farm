import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import '../../domain/entities/sale.dart';
import '../provider/sales_provider.dart';
import '../../data/services/sales_export_service.dart';
import '../../data/services/profit_margin_service.dart';
import '../../../expenses/presentation/provider/expense_provider.dart';
import '../../../batch/presentation/provider/batch_provider.dart';
import 'profit_margin_analysis_screen.dart';

class SalesAnalysisScreen extends StatefulWidget {
  const SalesAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SalesAnalysisScreen> createState() => _SalesAnalysisScreenState();
}

class _SalesAnalysisScreenState extends State<SalesAnalysisScreen> {
  // Date range filtering
  late DateTime _startDate;
  late DateTime _endDate;

  // Analytics data
  double _totalRevenue = 0.0;
  double _averageSaleValue = 0.0;
  int _totalSalesCount = 0;
  int _totalQuantitySold = 0;

  // Payment status breakdown
  int _paidCount = 0;
  int _pendingCount = 0;
  int _partiallyPaidCount = 0;
  double _paidAmount = 0.0;
  double _pendingAmount = 0.0;
  double _partiallyPaidAmount = 0.0;

  // Sale type breakdown
  Map<SaleType, double> _revenueByType = {};
  Map<SaleType, int> _countByType = {};

  // Top buyers
  List<Map<String, dynamic>> _topBuyers = [];

  // Chart data
  List<FlSpot> _revenueChartData = [];
  List<FlSpot> _quantityChartData = [];

  // Filter options
  SaleType? _selectedTypeFilter;
  PaymentStatus? _selectedPaymentFilter;
  String? _selectedBatchId; // Added batch filter

  bool _loading = false;
  List<Sale> _filteredSales = [];

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeData();
    });
  }

  void _setDefaultDateRange() {
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  void _analyzeData() {
    final salesProvider = context.read<SalesProvider>();
    final allSales = salesProvider.sales;

    // Filter sales by date range and optional filters
    final filteredSales = allSales.where((sale) {
      final inDateRange =
          sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              sale.saleDate.isBefore(_endDate.add(const Duration(days: 1)));

      final matchesType =
          _selectedTypeFilter == null || sale.saleType == _selectedTypeFilter;
      final matchesPayment = _selectedPaymentFilter == null ||
          sale.paymentStatus == _selectedPaymentFilter;
      final matchesBatch = _selectedBatchId == null || sale.batchId == _selectedBatchId;

      return inDateRange && matchesType && matchesPayment && matchesBatch;
    }).toList();

    setState(() {
      _filteredSales = filteredSales;
      _calculateMetrics(filteredSales);
      _calculateBreakdowns(filteredSales);
      _calculateTopBuyers(filteredSales);
      _buildChartData(filteredSales);
    });
  }

  void _calculateMetrics(List<Sale> sales) {
    _totalRevenue = 0.0;
    _totalSalesCount = sales.length;
    _totalQuantitySold = 0;

    for (final sale in sales) {
      _totalRevenue += sale.totalAmount;
      _totalQuantitySold += sale.quantity;
    }

    _averageSaleValue =
        _totalSalesCount > 0 ? _totalRevenue / _totalSalesCount : 0.0;
  }

  void _calculateBreakdowns(List<Sale> sales) {
    // Reset counters
    _paidCount = 0;
    _pendingCount = 0;
    _partiallyPaidCount = 0;
    _paidAmount = 0.0;
    _pendingAmount = 0.0;
    _partiallyPaidAmount = 0.0;
    _revenueByType.clear();
    _countByType.clear();

    for (final sale in sales) {
      // Payment status breakdown
      switch (sale.paymentStatus) {
        case PaymentStatus.paid:
          _paidCount++;
          _paidAmount += sale.totalAmount;
          break;
        case PaymentStatus.pending:
          _pendingCount++;
          _pendingAmount += sale.totalAmount;
          break;
        case PaymentStatus.partiallyPaid:
          _partiallyPaidCount++;
          _partiallyPaidAmount += sale.totalAmount;
          break;
      }

      // Sale type breakdown
      _revenueByType[sale.saleType] =
          (_revenueByType[sale.saleType] ?? 0.0) + sale.totalAmount;
      _countByType[sale.saleType] = (_countByType[sale.saleType] ?? 0) + 1;
    }
  }

  void _calculateTopBuyers(List<Sale> sales) {
    final Map<String, Map<String, dynamic>> buyerData = {};

    for (final sale in sales) {
      final buyerName = sale.buyerName ?? 'Unknown';

      if (!buyerData.containsKey(buyerName)) {
        buyerData[buyerName] = {
          'name': buyerName,
          'totalRevenue': 0.0,
          'salesCount': 0,
        };
      }

      buyerData[buyerName]!['totalRevenue'] += sale.totalAmount;
      buyerData[buyerName]!['salesCount'] += 1;
    }

    _topBuyers = buyerData.values.toList()
      ..sort((a, b) {
        final bRevenue = (b['totalRevenue'] as num).toDouble();
        final aRevenue = (a['totalRevenue'] as num).toDouble();
        return bRevenue.compareTo(aRevenue);
      });

    // Keep only top 5
    if (_topBuyers.length > 5) {
      _topBuyers = _topBuyers.sublist(0, 5);
    }
  }

  void _buildChartData(List<Sale> sales) {
    final Map<String, double> dailyRevenue = {};
    final Map<String, int> dailyQuantity = {};

    // Sort sales by date
    final sortedSales = sales.toList()
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

    for (final sale in sortedSales) {
      final dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
      dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + sale.totalAmount;
      dailyQuantity[dateKey] = (dailyQuantity[dateKey] ?? 0) + sale.quantity;
    }

    // Build chart spots
    _revenueChartData.clear();
    _quantityChartData.clear();

    final sortedDates = dailyRevenue.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      _revenueChartData.add(FlSpot(i.toDouble(), dailyRevenue[date]!));
      _quantityChartData
          .add(FlSpot(i.toDouble(), dailyQuantity[date]!.toDouble()));
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _analyzeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedBatchId != null
              ? 'Sales Analysis - ${_getBatchName()}'
              : 'Sales Analysis - All Batches',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportMenu(context),
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                _analyzeData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRangeSelector(),
                      const SizedBox(height: 16),
                      _buildBatchCards(),
                      const SizedBox(height: 24),
                      if (_selectedBatchId != null) ...[
                        _buildMetricsCards(),
                        const SizedBox(height: 24),
                        _buildPaymentStatusBreakdown(),
                        const SizedBox(height: 24),
                        _buildRevenueChart(),
                        const SizedBox(height: 24),
                        _buildQuantityChart(),
                        const SizedBox(height: 24),
                        _buildSaleTypeBreakdown(),
                        const SizedBox(height: 24),
                        _buildProfitInsights(),
                        const SizedBox(height: 24),
                        _buildTopBuyers(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _selectDateRange,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.date_range, color: AppColors.primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCards() {
    final batchProvider = context.watch<BatchProvider>();
    final batches = batchProvider.batches;
    final salesProvider = context.watch<SalesProvider>();

    if (batches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No batches available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Batch for Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...batches.map((batch) {
          final isSelected = batch.id == _selectedBatchId;
          final batchSales = salesProvider.sales
              .where((s) => 
                  s.batchId == batch.id &&
                  s.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
                  s.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
              .toList();
          
          final totalAmount = batchSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
          final totalQty = batchSales.fold<int>(0, (sum, s) => sum + s.quantity);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedBatchId = isSelected ? null : batch.id;
                  });
                  _analyzeData();
                },
                borderRadius: BorderRadius.circular(12),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (batch.breed != null)
                                  Text(
                                    batch.breed!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Selected',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
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
                              icon: Icons.shopping_bag_outlined,
                              label: 'Sales',
                              value: '${batchSales.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBatchInfoItem(
                              icon: Icons.inventory_2_outlined,
                              label: 'Quantity',
                              value: '$totalQty',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildBatchInfoItem(
                              icon: Icons.attach_money,
                              label: 'Revenue',
                              value: batchSales.isNotEmpty 
                                  ? '${batchSales.first.currency}${totalAmount.toStringAsFixed(0)}'
                                  : '\$0',
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
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final batchProvider = context.watch<BatchProvider>();
    final batches = batchProvider.batches;
    
    return Column(
      children: [
        // Batch filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedBatchId,
              hint: const Text('Filter by Batch'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Batches'),
                ),
                ...batches.map((batch) => DropdownMenuItem<String>(
                      value: batch.id,
                      child: Text('${batch.name} (${batch.birdType.name})'),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedBatchId = value);
                _analyzeData();
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Type and Payment filters
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown<SaleType>(
                label: 'Type',
                value: _selectedTypeFilter,
                items: SaleType.values,
                itemLabel: (type) => type.displayName,
                onChanged: (value) {
                  setState(() => _selectedTypeFilter = value);
                  _analyzeData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown<PaymentStatus>(
                label: 'Payment',
                value: _selectedPaymentFilter,
                items: PaymentStatus.values,
                itemLabel: (status) => status.displayName,
                onChanged: (value) {
                  setState(() => _selectedPaymentFilter = value);
                  _analyzeData();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(label),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('All $label'),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _getBatchName() {
    if (_selectedBatchId == null) return 'All Batches';
    final batchProvider = context.read<BatchProvider>();
    try {
      final batch = batchProvider.batches.firstWhere(
        (b) => b.id == _selectedBatchId,
      );
      return batch.name;
    } catch (e) {
      return 'Unknown Batch';
    }
  }

  Widget _buildMetricsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
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
                title: 'Total Revenue',
                value: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(_totalRevenue),
                icon: Icons.attach_money,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Sales Count',
                value: _totalSalesCount.toString(),
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Avg Sale Value',
                value: NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                    .format(_averageSaleValue),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Quantity',
                value: _totalQuantitySold.toString(),
                icon: Icons.inventory_2,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBreakdown() {
    final total = _paidCount + _pendingCount + _partiallyPaidCount;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPaymentStatusRow(
                  'Paid',
                  _paidCount,
                  _paidAmount,
                  Colors.green,
                  total,
                ),
                const Divider(),
                _buildPaymentStatusRow(
                  'Pending',
                  _pendingCount,
                  _pendingAmount,
                  Colors.orange,
                  total,
                ),
                const Divider(),
                _buildPaymentStatusRow(
                  'Partially Paid',
                  _partiallyPaidCount,
                  _partiallyPaidAmount,
                  Colors.blue,
                  total,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusRow(
    String label,
    int count,
    double amount,
    Color color,
    int total,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count sales (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _totalRevenue / 5,
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
                        interval: (_revenueChartData.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _revenueChartData.length) {
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
                  maxX: (_revenueChartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _revenueChartData
                          .map((spot) => spot.y)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _revenueChartData,
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _revenueChartData.length < 15,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 0)
                                .format(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityChart() {
    if (_quantityChartData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity Sold Trend',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval:
                            (_quantityChartData.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < _quantityChartData.length) {
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
                  maxX: (_quantityChartData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _quantityChartData
                          .map((spot) => spot.y)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _quantityChartData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _quantityChartData.length < 15,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()} units',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleTypeBreakdown() {
    if (_revenueByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue by Sale Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _revenueByType.entries.map((entry) {
                final percentage = _totalRevenue > 0
                    ? (entry.value / _totalRevenue * 100)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getSaleTypeIcon(entry.key),
                                size: 20,
                                color: _getSaleTypeColor(entry.key),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            NumberFormat.currency(
                                    symbol: '\$', decimalDigits: 0)
                                .format(entry.value),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getSaleTypeColor(entry.key),
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
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: _getSaleTypeColor(entry.key),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_countByType[entry.key] ?? 0} sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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

  Widget _buildTopBuyers() {
    if (_topBuyers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Buyers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _topBuyers.asMap().entries.map((entry) {
                final index = entry.key;
                final buyer = entry.value;
                final isLast = index == _topBuyers.length - 1;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryGreen,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        buyer['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${buyer['salesCount']} sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                            .format(buyer['totalRevenue']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    if (!isLast) const Divider(),
                  ],
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

  void _showExportMenu(BuildContext context) {
    if (_filteredSales.isEmpty) {
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
                      'Export Analysis',
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
                subtitle: Text('${_filteredSales.length} sales with analytics'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _exportPDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export as CSV'),
                subtitle: Text(
                    '${_filteredSales.length} sales in spreadsheet format'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _exportCSV();
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
                  _sharePDF();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Share CSV Data'),
                subtitle: const Text('Share spreadsheet file'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _shareCSV();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPDF() async {
    try {
      final file = await SalesExportService.exportToPDF(
        _filteredSales,
        title: 'Sales Analysis Report',
        startDate: _startDate,
        endDate: _endDate,
        analytics: {
          'totalRevenue': _totalRevenue,
          'averageSaleValue': _averageSaleValue,
          'totalSalesCount': _totalSalesCount,
          'totalQuantitySold': _totalQuantitySold,
        },
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
              onPressed: () => _sharePDF(),
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

  Future<void> _exportCSV() async {
    try {
      final file = await SalesExportService.exportToCSV(_filteredSales);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareCSV(),
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

  Future<void> _sharePDF() async {
    try {
      await SalesExportService.exportAndSharePDF(
        _filteredSales,
        title: 'Sales Analysis Report',
        startDate: _startDate,
        endDate: _endDate,
        analytics: {
          'totalRevenue': _totalRevenue,
          'averageSaleValue': _averageSaleValue,
          'totalSalesCount': _totalSalesCount,
          'totalQuantitySold': _totalQuantitySold,
        },
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

  Widget _buildProfitInsights() {
    final batchProvider = context.read<BatchProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final batches = batchProvider.batches;
    final expenses = expenseProvider.expenses;

    // Calculate overall metrics for all batches
    final overallMetrics = ProfitMarginService.calculateOverallMetrics(
      batches: batches,
      allSales: _filteredSales,
      allExpenses: expenses.where((e) {
        // Filter expenses to match date range
        return e.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            e.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList(),
    );

    final totalRevenue = (overallMetrics['totalRevenue'] as num).toDouble();
    final totalCost = (overallMetrics['totalCost'] as num).toDouble();
    final overallProfit = (overallMetrics['overallProfit'] as num).toDouble();
    final profitMargin = (overallMetrics['overallMargin'] as num).toDouble();
    final profitableBatches = overallMetrics['profitableBatches'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profit Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.trending_up),
              label: const Text('View Detailed'),
              onPressed: () {
                if (_selectedBatchId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Select a batch to view detailed profit analysis'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                // Navigate to profit margin analysis screen with selected batch
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfitMarginAnalysisScreen(
                      batchId: _selectedBatchId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: overallProfit >= 0
              ? AppColors.primaryGreen.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
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
                          'Overall Profit',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                              .format(overallProfit),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: overallProfit >= 0
                                ? AppColors.primaryGreen
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${profitMargin.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Text(
                            'Margin',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
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
                      child: _buildProfitMetric(
                        'Revenue',
                        NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                            .format(totalRevenue),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProfitMetric(
                        'Cost',
                        NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                            .format(totalCost),
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProfitMetric(
                        'Profitable',
                        '$profitableBatches/${batches.length}',
                        AppColors.primaryGreen,
                      ),
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

  Widget _buildProfitMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _shareCSV() async {
    try {
      await SalesExportService.exportAndShareCSV(_filteredSales);
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
}
