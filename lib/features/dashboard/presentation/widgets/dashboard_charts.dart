import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_stats.dart';

class BatchStatusPieChart extends StatelessWidget {
  final DashboardStats stats;

  const BatchStatusPieChart({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = stats.totalBatches;
    if (total == 0) {
      return const Center(
        child: Text('No batches yet'),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections: [
            if (stats.totalActiveBatches > 0)
              PieChartSectionData(
                value: stats.totalActiveBatches.toDouble(),
                title: '${stats.totalActiveBatches}',
                color: Colors.green,
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (stats.totalPlannedBatches > 0)
              PieChartSectionData(
                value: stats.totalPlannedBatches.toDouble(),
                title: '${stats.totalPlannedBatches}',
                color: Colors.orange,
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (stats.totalCompletedBatches > 0)
              PieChartSectionData(
                value: stats.totalCompletedBatches.toDouble(),
                title: '${stats.totalCompletedBatches}',
                color: Colors.blue,
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}

class BatchStatusLegend extends StatelessWidget {
  final DashboardStats stats;

  const BatchStatusLegend({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Active', stats.totalActiveBatches, Colors.green),
        _buildLegendItem('Planned', stats.totalPlannedBatches, Colors.orange),
        _buildLegendItem('Completed', stats.totalCompletedBatches, Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class MortalityTrendChart extends StatelessWidget {
  final List<BatchPerformanceMetric> metrics;

  const MortalityTrendChart({Key? key, required this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort by day number for proper chart display
    final sortedMetrics = List<BatchPerformanceMetric>.from(metrics)
      ..sort((a, b) => a.currentDay.compareTo(b.currentDay));

    final spots = sortedMetrics
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.mortalityRate,
            ))
        .toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < sortedMetrics.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'D${sortedMetrics[value.toInt()].currentDay}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 40,
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
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            minX: 0,
            maxX: (sortedMetrics.length - 1).toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.red,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurvivalRateBarChart extends StatelessWidget {
  final List<BatchPerformanceMetric> metrics;

  const SurvivalRateBarChart({Key? key, required this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final topMetrics = metrics.take(5).toList();

    return AspectRatio(
      aspectRatio: 1.3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${topMetrics[group.x.toInt()].batchName}\n${rod.toY.toStringAsFixed(1)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < topMetrics.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          topMetrics[value.toInt()].batchName.substring(0, 
                            topMetrics[value.toInt()].batchName.length > 8 
                              ? 8 
                              : topMetrics[value.toInt()].batchName.length),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 40,
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
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            barGroups: topMetrics
                .asMap()
                .entries
                .map((entry) => BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.survivalRate,
                          color: entry.value.survivalRate > 90
                              ? Colors.green
                              : entry.value.survivalRate > 80
                                  ? Colors.orange
                                  : Colors.red,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
