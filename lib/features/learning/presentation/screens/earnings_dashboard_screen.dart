import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _loading = true;
  String? _currentUserId;

  // Date range filtering
  late DateTime _startDate;
  late DateTime _endDate;

  // Earnings data
  double _totalEarnings = 0.0;
  double _monthlyEarnings = 0.0;
  int _activeSubscribers = 0;
  double _averageMonthlyValue = 0.0;

  // Chart data
  List<FlSpot> _earningsChartData = [];
  Map<String, double> _earningsByPlan = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _setDefaultDateRange();
    _loadEarnings();
  }

  void _setDefaultDateRange() {
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 90));
  }

  Future<void> _loadEarnings() async {
    if (_currentUserId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load all paid subscriptions for this creator
      final response = await Supabase.instance.client
          .from('paid_subscriptions')
          .select()
          .eq('plan_id', _currentUserId!)
          .gte('created_at', _startDate.toIso8601String())
          .lte('created_at', _endDate.toIso8601String())
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _subscriptions = List<Map<String, dynamic>>.from(response);
          _calculateEarnings();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading earnings: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading earnings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateEarnings() {
    _totalEarnings = 0.0;
    _monthlyEarnings = 0.0;
    _activeSubscribers = 0;
    _earningsByPlan.clear();
    _earningsChartData.clear();

    Map<String, double> dailyEarnings = {};

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (final subscription in _subscriptions) {
      final amount =
          double.tryParse(subscription['amount']?.toString() ?? '0') ?? 0.0;
      final planId = subscription['plan_id'] ?? 'Unknown';
      final createdAt = DateTime.tryParse(
        subscription['created_at']?.toString() ?? '',
      );

      // Total earnings
      _totalEarnings += amount;

      // Monthly earnings (last 30 days)
      if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
        _monthlyEarnings += amount;
      }

      // Active subscribers
      final currentPeriodEnd = DateTime.tryParse(
        subscription['current_period_end']?.toString() ?? '',
      );
      if (currentPeriodEnd != null && currentPeriodEnd.isAfter(now)) {
        _activeSubscribers++;
      }

      // Earnings by plan
      _earningsByPlan[planId] = (_earningsByPlan[planId] ?? 0.0) + amount;

      // Daily earnings for chart
      if (createdAt != null) {
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        dailyEarnings[dateKey] = (dailyEarnings[dateKey] ?? 0.0) + amount;
      }
    }

    // Calculate average monthly value
    _averageMonthlyValue = _activeSubscribers > 0 ? _totalEarnings / 3 : 0.0;

    // Build chart data from daily earnings
    _buildChartData(dailyEarnings);
  }

  void _buildChartData(Map<String, double> dailyEarnings) {
    final sortedDates = dailyEarnings.keys.toList()..sort();

    double cumulativeEarnings = 0.0;
    for (int i = 0; i < sortedDates.length; i++) {
      cumulativeEarnings += dailyEarnings[sortedDates[i]]!;
      _earningsChartData.add(
        FlSpot(i.toDouble(), cumulativeEarnings),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _loading = true;
      });
      await _loadEarnings();
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDateRange() {
    final start = '${_startDate.day}/${_startDate.month}/${_startDate.year}';
    final end = '${_endDate.day}/${_endDate.month}/${_endDate.year}';
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Selector
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date Range',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatDateRange(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _selectDateRange,
                                  icon: const Icon(Icons.calendar_today),
                                  color: AppColors.primaryGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Key Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          title: 'Total Earnings',
                          value: _formatCurrency(_totalEarnings),
                          icon: Icons.trending_up,
                          color: AppColors.primaryGreen,
                        ),
                        _buildMetricCard(
                          title: 'Monthly Earnings',
                          value: _formatCurrency(_monthlyEarnings),
                          icon: Icons.calendar_month,
                          color: Colors.blue,
                        ),
                        _buildMetricCard(
                          title: 'Active Subscribers',
                          value: _activeSubscribers.toString(),
                          icon: Icons.people,
                          color: Colors.orange,
                        ),
                        _buildMetricCard(
                          title: 'Avg Monthly Value',
                          value: _formatCurrency(_averageMonthlyValue),
                          icon: Icons.show_chart,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cumulative Earnings Chart
                    if (_earningsChartData.isNotEmpty) ...[
                      const Text(
                        'Cumulative Earnings Trend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 300,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: _getChartInterval(),
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey[300],
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(),
                                  topTitles: const AxisTitles(),
                                  bottomTitles: const AxisTitles(),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, meta) {
                                        return Text(
                                          '\$${value.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                      reservedSize: 60,
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _earningsChartData,
                                    isCurved: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryGreen.withOpacity(0.6),
                                        AppColors.primaryGreen,
                                      ],
                                    ),
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryGreen
                                              .withOpacity(0.1),
                                          AppColors.primaryGreen
                                              .withOpacity(0.01),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Earnings by Plan
                    if (_earningsByPlan.isNotEmpty) ...[
                      const Text(
                        'Earnings by Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _earningsByPlan.entries
                                .map(
                                  (entry) => _buildPlanEarningsRow(
                                    entry.key,
                                    entry.value,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Subscription List
                    if (_subscriptions.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No earnings yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your earnings will appear here\nonce farmers subscribe',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      const Text(
                        'Recent Subscriptions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = _subscriptions[index];
                          return _buildSubscriptionItem(
                            subscription,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanEarningsRow(String planId, double earnings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(earnings),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(
    Map<String, dynamic> subscription,
  ) {
    final amount = double.tryParse(
          subscription['amount']?.toString() ?? '0',
        ) ??
        0.0;
    final planId = subscription['plan_id'] ?? 'Plan';
    final createdAt = DateTime.tryParse(
      subscription['created_at']?.toString() ?? '',
    );
    final currentPeriodEnd = DateTime.tryParse(
      subscription['current_period_end']?.toString() ?? '',
    );

    final isActive =
        currentPeriodEnd != null && currentPeriodEnd.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        planId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Expired',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (currentPeriodEnd != null) ...[
              const SizedBox(height: 8),
              Text(
                'Renews: ${_formatDate(currentPeriodEnd)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _getChartInterval() {
    if (_totalEarnings < 100) return 10;
    if (_totalEarnings < 500) return 50;
    if (_totalEarnings < 1000) return 100;
    if (_totalEarnings < 5000) return 500;
    return 1000;
  }
}
