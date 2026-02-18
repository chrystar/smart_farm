import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/dashboard_charts.dart';
import '../../../../../features/batch/presentation/provider/batch_provider.dart';

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
        title: const Text(
          'Poultriz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVaccineBatche(),
                  const SizedBox(height: 24),

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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
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

  Widget _buildVaccineBatche() {
    return Consumer<BatchProvider>(
      builder: (context, batchProvider, _) {
        final activeBatches = batchProvider.batches
            .where((b) => b.status.name == 'active')
            .toList();
        if (activeBatches.isEmpty) return const SizedBox.shrink();
        final activeBatch = activeBatches.first;
        final startDate = activeBatch.startDate;
        if (startDate == null) return const SizedBox.shrink();
        final currentDay = DateTime.now().difference(startDate).inDays + 1;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getDefaultVaccinationSchedules(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final schedules = snapshot.data!;
            final dueVaccines = <Map<String, dynamic>>[];
            
            for (final schedule in schedules) {
              final vaccineName = schedule['vaccine_name'] as String?;
              final startDay = schedule['start_day'] as int?;
              final endDay = schedule['end_day'] as int?;
              
              if (vaccineName == null || startDay == null) continue;
              
              // Check if current day falls within the vaccine schedule
              final lastDay = endDay ?? startDay; // Single day if no end_day
              if (currentDay >= startDay && currentDay <= lastDay) {
                // Calculate duration display
                String dayDisplay;
                if (startDay == lastDay) {
                  dayDisplay = 'Day $startDay';
                } else {
                  final duration = lastDay - startDay + 1;
                  dayDisplay = 'Days $startDay-$lastDay ($duration days)';
                }
                
                dueVaccines.add({
                  'name': vaccineName,
                  'days': dayDisplay,
                });
              }
            }
            
            if (dueVaccines.isEmpty) return const SizedBox.shrink();
            
            return Container(
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Medication',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                '${activeBatch.name} • Day $currentDay',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...dueVaccines.map((vaccine) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              vaccine['name'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          Text(
                            vaccine['days'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  /// Get the default vaccination schedule from the data source
  Future<List<Map<String, dynamic>>> _getDefaultVaccinationSchedules() async {
    // Using start_day and end_day for duration instead of parsing notes
    return [
      {
        'vaccine_name': 'Glucose',
        'start_day': 1,
        'end_day': 1,
      },
      {
        'vaccine_name': 'Antibiotic + Vitamin',
        'start_day': 2,
        'end_day': 5,
      },
      {
        'vaccine_name': 'Vaccine',
        'start_day': 6,
        'end_day': 6,
      },
      {
        'vaccine_name': 'Coccidiostat',
        'start_day': 7,
        'end_day': 9,
      },
      {
        'vaccine_name': 'Vitamin',
        'start_day': 10,
        'end_day': 10,
      },
      {
        'vaccine_name': 'Vaccine',
        'start_day': 11,
        'end_day': 11,
      },
      {
        'vaccine_name': 'Vitamin',
        'start_day': 12,
        'end_day': 12,
      },
      {
        'vaccine_name': 'Antibiotics',
        'start_day': 13,
        'end_day': 16,
      },
      {
        'vaccine_name': 'Coccidiostat',
        'start_day': 17,
        'end_day': 19,
      },
      {
        'vaccine_name': 'Vitamin',
        'start_day': 20,
        'end_day': 20,
      },
      {
        'vaccine_name': 'Vaccine',
        'start_day': 21,
        'end_day': 21,
      },
      {
        'vaccine_name': 'Antibiotics',
        'start_day': 22,
        'end_day': 27,
      },
      {
        'vaccine_name': 'Vaccine',
        'start_day': 28,
        'end_day': 28,
      },
      {
        'vaccine_name': 'Vitamin',
        'start_day': 29,
        'end_day': 29,
      },
      {
        'vaccine_name': 'Acidifier',
        'start_day': 30,
        'end_day': 34,
      },
      {
        'vaccine_name': 'Coccidiostat',
        'start_day': 35,
        'end_day': 39,
      },
      {
        'vaccine_name': 'Dewormer',
        'start_day': 40,
        'end_day': 40,
      },
      {
        'vaccine_name': 'Vitamin',
        'start_day': 41,
        'end_day': 46,
      },
      {
        'vaccine_name': 'Acidifier',
        'start_day': 47,
        'end_day': 50,
      },
      {
        'vaccine_name': 'Symptomatic Treatment',
        'start_day': 51,
        'end_day': 51,
      },
    ];
  }
}
