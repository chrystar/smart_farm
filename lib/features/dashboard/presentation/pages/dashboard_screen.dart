import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/dashboard_charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Defer loading to after first frame to avoid notify during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final userId = SupabaseService().currentUserId;
    if (userId != null) {
      await context.read<DashboardProvider>().loadDashboard(userId);
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: (){},
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboard,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.stats;
          if (stats == null) {
            return const Center(child: Text('No data available'));
          }

          return RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewCards(stats),
                  const SizedBox(height: 24),

                    // Alerts
                  if (stats.alerts.isNotEmpty) ...[
                    _buildSectionTitle('Alerts'),
                    const SizedBox(height: 12),
                    _buildAlerts(stats.alerts),
                    const SizedBox(height: 24),
                  ],

                  // Batch Status Distribution
                  _buildSectionTitle('Batch Distribution'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          BatchStatusPieChart(stats: stats),
                          const SizedBox(height: 16),
                          BatchStatusLegend(stats: stats),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  
                  // Investment Breakdown
                  if (stats.investmentByCurrency.isNotEmpty) ...[
                    _buildSectionTitle('Investment by Currency'),
                    const SizedBox(height: 12),
                    _buildInvestmentBreakdown(stats.investmentByCurrency),
                    const SizedBox(height: 24),
                  ],


                  // Recent Activity
                  if (stats.recentActivities.isNotEmpty) ...[
                    _buildSectionTitle('Recent Activity'),
                    const SizedBox(height: 12),
                    _buildRecentActivities(stats.recentActivities),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverviewCards(DashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Batches',
          stats.totalActiveBatches.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Live Birds',
          stats.totalLiveBirds.toString(),
          Icons.pets,
          Colors.blue,
        ),
        _buildStatCard(
          'Planned Batches',
          stats.totalPlannedBatches.toString(),
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Mortality',
          '${stats.averageMortalityRate.toStringAsFixed(1)}%',
          Icons.trending_down,
          stats.averageMortalityRate > 10 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentBreakdown(Map<String, double> investments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: investments.entries.map((entry) {
            final symbol = _getCurrencySymbol(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$symbol${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlerts(List<BatchAlert> alerts) {
    return Column(
      children: alerts.take(5).map((alert) {
        Color alertColor;
        IconData alertIcon;

        switch (alert.type) {
          case AlertType.highMortality:
            alertColor = Colors.red;
            alertIcon = Icons.warning;
            break;
          case AlertType.missingRecord:
            alertColor = Colors.orange;
            alertIcon = Icons.info;
            break;
          case AlertType.lowSurvivalRate:
            alertColor = Colors.amber;
            alertIcon = Icons.error_outline;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          child: ListTile(
            leading: Icon(alertIcon, color: alertColor),
            title: Text(alert.batchName),
            subtitle: Text(alert.message),
            trailing: Text(
              DateFormat('MMM dd').format(alert.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceMetrics(List<BatchPerformanceMetric> metrics) {
    return Column(
      children: metrics.take(5).map((metric) {
        final symbol = _getCurrencySymbol(metric.currency);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        metric.batchName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Day ${metric.currentDay}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Survival',
                        '${metric.survivalRate.toStringAsFixed(1)}%',
                        metric.survivalRate > 90 ? Colors.green : Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Live Birds',
                        '${metric.liveBirds}/${metric.initialQuantity}',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                if (metric.purchaseCost != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Cost/Bird',
                          '$symbol${metric.costPerBird.toStringAsFixed(2)}',
                          Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Cost/Live',
                          '$symbol${metric.costPerLiveBird.toStringAsFixed(2)}',
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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

  Widget _buildRecentActivities(List<RecentActivity> activities) {
    return Card(
      child: Column(
        children: activities.take(10).map((activity) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: activity.deaths > 0
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Icon(
                activity.deaths > 0 ? Icons.trending_down : Icons.check,
                color: activity.deaths > 0 ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            title: Text(activity.batchName),
            subtitle: Text(
              'Day ${activity.dayNumber}: ${activity.deaths} deaths',
            ),
            trailing: Text(
              DateFormat('MMM dd').format(activity.recordDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }).toList(),
      ),
    );
  }
}
