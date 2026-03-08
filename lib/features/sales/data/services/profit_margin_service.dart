import 'package:smart_farm/features/sales/domain/entities/sale.dart';
import 'package:smart_farm/features/expenses/domain/entities/expense.dart';
import 'package:smart_farm/features/batch/domain/entities/batch.dart';

/// Profit analysis result with comprehensive metrics
class ProfitAnalysis {
  final String batchId;
  final String batchName;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double netProfit;
  final double profitMargin; // Percentage
  final double roi; // Return on Investment percentage
  final int breakEvenQuantity;
  final DateTime? breakEvenDate;
  final Map<SaleType, ProfitByType> profitByType;
  final List<ProfitPoint> profitTimeline;
  final double costPerUnit;
  final double revenuePerUnit;
  final List<ExpenseBreakdown> expenseBreakdown;

  ProfitAnalysis({
    required this.batchId,
    required this.batchName,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.netProfit,
    required this.profitMargin,
    required this.roi,
    required this.breakEvenQuantity,
    this.breakEvenDate,
    required this.profitByType,
    required this.profitTimeline,
    required this.costPerUnit,
    required this.revenuePerUnit,
    required this.expenseBreakdown,
  });
}

/// Profit data by sale type
class ProfitByType {
  final SaleType saleType;
  final int quantitySold;
  final double totalRevenue;
  final double totalCost; // Allocated cost
  final double grossProfit;
  final double profitMargin; // Percentage
  final double costPerUnit;
  final double revenuePerUnit;

  ProfitByType({
    required this.saleType,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.costPerUnit,
    required this.revenuePerUnit,
  });
}

/// Timeline point for profit progression
class ProfitPoint {
  final DateTime date;
  final double cumulativeRevenue;
  final double cumulativeCost;
  final double cumulativeProfit;
  final int quantitySold;

  ProfitPoint({
    required this.date,
    required this.cumulativeRevenue,
    required this.cumulativeCost,
    required this.cumulativeProfit,
    required this.quantitySold,
  });
}

/// Expense breakdown for visualization
class ExpenseBreakdown {
  final ExpenseCategory category;
  final String label;
  final double amount;
  final double percentage;

  ExpenseBreakdown({
    required this.category,
    required this.label,
    required this.amount,
    required this.percentage,
  });
}

/// Profit Margin Analysis Service
/// Calculates cost vs revenue, profit margins, ROI, and break-even analysis
class ProfitMarginService {
  /// Calculate comprehensive profit analysis for a batch
  static ProfitAnalysis analyzeBatch({
    required Batch batch,
    required List<Sale> batchSales,
    required List<Expense> batchExpenses,
  }) {
    // Calculate total revenue and quantity
    final totalRevenue =
        batchSales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
    final totalQuantitySold =
        batchSales.fold<int>(0, (sum, sale) => sum + sale.quantity);

    // Calculate total expenses
    final totalCost =
        batchExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    // Calculate profits
    final grossProfit = totalRevenue - totalCost;
    final netProfit =
        grossProfit; // Same as gross for now (can add more deductions)

    // Calculate per-unit metrics
    // Cost per unit = total cost ÷ total birds RAISED (birds actually received, not sold)
    // Use actualQuantity (birds received on batch start) or fallback to expectedQuantity
    final birdsRaised = batch.actualQuantity ?? batch.expectedQuantity;
    final costPerUnit =
        (birdsRaised > 0 ? totalCost / birdsRaised : 0.0)
            .toDouble();
    // Revenue per unit = total revenue ÷ birds SOLD
    final revenuePerUnit =
        (totalQuantitySold > 0 ? totalRevenue / totalQuantitySold : 0.0)
            .toDouble();

    // Calculate profit margin percentage
    final profitMargin =
        (totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0).toDouble();

    // Calculate ROI percentage
    final roi =
        (totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0).toDouble();

    // Calculate break-even quantity
    final breakEvenQuantity = _calculateBreakEvenQuantity(
      batch: batch,
      batchExpenses: batchExpenses,
      revenuePerUnit: revenuePerUnit,
    );

    // Calculate break-even date
    final breakEvenDate = _calculateBreakEvenDate(
      batchSales: batchSales,
      breakEvenQuantity: breakEvenQuantity,
    );

    // Analyze profit by sale type
    final profitByType = _analyzeProfitByType(
      batchSales: batchSales,
      totalCost: totalCost,
      totalQuantitySold: totalQuantitySold,
    );

    // Build profit timeline
    final profitTimeline = _buildProfitTimeline(
      batchSales: batchSales,
      batchExpenses: batchExpenses,
    );

    // Expense breakdown
    final expenseBreakdown = _buildExpenseBreakdown(
      batchExpenses: batchExpenses,
      totalCost: totalCost,
    );

    return ProfitAnalysis(
      batchId: batch.id,
      batchName: batch.name,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      netProfit: netProfit,
      profitMargin: profitMargin,
      roi: roi,
      breakEvenQuantity: breakEvenQuantity,
      breakEvenDate: breakEvenDate,
      profitByType: profitByType,
      profitTimeline: profitTimeline,
      costPerUnit: costPerUnit,
      revenuePerUnit: revenuePerUnit,
      expenseBreakdown: expenseBreakdown,
    );
  }

  /// Calculate break-even quantity
  static int _calculateBreakEvenQuantity({
    required Batch batch,
    required List<Expense> batchExpenses,
    required double revenuePerUnit,
  }) {
    final totalCost =
        batchExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    if (revenuePerUnit <= 0 || totalCost <= 0) {
      return 0;
    }

    return (totalCost / revenuePerUnit).ceil();
  }

  /// Calculate when batch reaches break-even
  static DateTime? _calculateBreakEvenDate({
    required List<Sale> batchSales,
    required int breakEvenQuantity,
  }) {
    if (batchSales.isEmpty || breakEvenQuantity <= 0) {
      return null;
    }

    int quantityAccumulated = 0;
    final sortedSales = batchSales.toList()
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

    for (final sale in sortedSales) {
      quantityAccumulated += sale.quantity;
      if (quantityAccumulated >= breakEvenQuantity) {
        return sale.saleDate;
      }
    }

    return null; // Break-even not reached
  }

  /// Analyze profit by sale type
  static Map<SaleType, ProfitByType> _analyzeProfitByType({
    required List<Sale> batchSales,
    required double totalCost,
    required int totalQuantitySold,
  }) {
    final result = <SaleType, ProfitByType>{};

    // Group sales by type
    final salesByType = <SaleType, List<Sale>>{};
    for (final sale in batchSales) {
      salesByType.putIfAbsent(sale.saleType, () => []).add(sale);
    }

    // Calculate for each type
    for (final entry in salesByType.entries) {
      final saleType = entry.key;
      final sales = entry.value;

      final quantitySold =
          sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
      final typeRevenue =
          sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);

      // Allocate cost proportionally
      final costRatio =
          totalQuantitySold > 0 ? quantitySold / totalQuantitySold : 0;
      final allocatedCost = totalCost * costRatio;

      final typeProfit = typeRevenue - allocatedCost;
      final costPerUnit =
          (quantitySold > 0 ? allocatedCost / quantitySold : 0.0).toDouble();
      final revenuePerUnit =
          (quantitySold > 0 ? typeRevenue / quantitySold : 0.0).toDouble();
      final profitMargin =
          (typeRevenue > 0 ? (typeProfit / typeRevenue) * 100 : 0.0).toDouble();

      result[saleType] = ProfitByType(
        saleType: saleType,
        quantitySold: quantitySold,
        totalRevenue: typeRevenue,
        totalCost: allocatedCost,
        grossProfit: typeProfit,
        profitMargin: profitMargin,
        costPerUnit: costPerUnit,
        revenuePerUnit: revenuePerUnit,
      );
    }

    return result;
  }

  /// Build profit progression timeline
  static List<ProfitPoint> _buildProfitTimeline({
    required List<Sale> batchSales,
    required List<Expense> batchExpenses,
  }) {
    final points = <ProfitPoint>[];

    // Sort sales by date
    final sortedSales = batchSales.toList()
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

    // Sort expenses by date
    final sortedExpenses = batchExpenses.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Merge and process events chronologically
    final allEvents = <DateTime, Map<String, dynamic>>{};

    for (final expense in sortedExpenses) {
      allEvents.putIfAbsent(expense.date, () => {})['expense'] = expense;
    }

    for (final sale in sortedSales) {
      allEvents.putIfAbsent(sale.saleDate, () => {})['sale'] = sale;
    }

    // Process in chronological order
    final sortedDates = allEvents.keys.toList()..sort();
    double cumulativeRevenue = 0;
    double cumulativeCost = 0;
    int cumulativeQuantity = 0;

    for (final date in sortedDates) {
      final events = allEvents[date]!;

      if (events.containsKey('expense')) {
        final expense = events['expense'] as Expense;
        cumulativeCost += expense.amount;
      }

      if (events.containsKey('sale')) {
        final sale = events['sale'] as Sale;
        cumulativeRevenue += sale.totalAmount;
        cumulativeQuantity += sale.quantity;
      }

      points.add(
        ProfitPoint(
          date: date,
          cumulativeRevenue: cumulativeRevenue,
          cumulativeCost: cumulativeCost,
          cumulativeProfit: cumulativeRevenue - cumulativeCost,
          quantitySold: cumulativeQuantity,
        ),
      );
    }

    return points;
  }

  /// Build expense category breakdown
  static List<ExpenseBreakdown> _buildExpenseBreakdown({
    required List<Expense> batchExpenses,
    required double totalCost,
  }) {
    final breakdown = <ExpenseCategory, double>{};

    // Group expenses by category
    for (final expense in batchExpenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }

    // Convert to ExpenseBreakdown
    return breakdown.entries.map((entry) {
      final percentage =
          (totalCost > 0 ? (entry.value / totalCost) * 100 : 0.0).toDouble();
      return ExpenseBreakdown(
        category: entry.key,
        label: _getCategoryLabel(entry.key),
        amount: entry.value,
        percentage: percentage,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Get display label for expense category
  static String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.birds:
        return 'Chicks/Birds';
      case ExpenseCategory.medicine:
        return 'Medicine & Vaccines';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.labor:
        return 'Labor';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Calculate overall profitability metrics for all batches
  static Map<String, dynamic> calculateOverallMetrics({
    required List<Batch> batches,
    required List<Sale> allSales,
    required List<Expense> allExpenses,
  }) {
    double totalRevenue = 0;
    double totalCost = 0;
    int totalQuantitySold = 0;
    int profitableBatches = 0;
    int unprofitableBatches = 0;

    for (final batch in batches) {
      final batchSales = allSales.where((s) => s.batchId == batch.id).toList();
      final batchExpenses =
          allExpenses.where((e) => e.batchId == batch.id).toList();

      final batchRevenue =
          batchSales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
      final batchCost =
          batchExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      final batchQuantity =
          batchSales.fold<int>(0, (sum, sale) => sum + sale.quantity);

      totalRevenue += batchRevenue;
      totalCost += batchCost;
      totalQuantitySold += batchQuantity;

      if (batchRevenue >= batchCost) {
        profitableBatches++;
      } else {
        unprofitableBatches++;
      }
    }

    final overallProfit = totalRevenue - totalCost;
    final overallMargin =
        totalRevenue > 0 ? (overallProfit / totalRevenue) * 100 : 0;
    final overallRoi = totalCost > 0 ? (overallProfit / totalCost) * 100 : 0;

    return {
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'overallProfit': overallProfit,
      'overallMargin': overallMargin,
      'overallRoi': overallRoi,
      'totalQuantitySold': totalQuantitySold,
      'profitableBatches': profitableBatches,
      'unprofitableBatches': unprofitableBatches,
      'profitablePercentage':
          batches.isNotEmpty ? (profitableBatches / batches.length) * 100 : 0,
    };
  }

  /// Check if a sale is profitable
  static bool isSaleProfitable({
    required Sale sale,
    required double costPerUnit,
  }) {
    return sale.pricePerUnit > costPerUnit;
  }

  /// Calculate days to break-even
  static int? daysToBreaKEven({
    required ProfitAnalysis analysis,
  }) {
    if (analysis.breakEvenDate == null || analysis.profitTimeline.isEmpty) {
      return null;
    }

    final firstSaleDate = analysis.profitTimeline.first.date;
    return analysis.breakEvenDate!.difference(firstSaleDate).inDays;
  }

  /// Get profit status emoji/label
  static String getProfitStatusLabel(double profitMargin) {
    if (profitMargin >= 30) return 'Excellent';
    if (profitMargin >= 20) return 'Good';
    if (profitMargin >= 10) return 'Fair';
    if (profitMargin >= 0) return 'Minimal';
    return 'Loss';
  }

  /// Get profit status color (as hex string)
  static String getProfitStatusColor(double profitMargin) {
    if (profitMargin >= 30) return '#28a745'; // Green
    if (profitMargin >= 20) return '#17a2b8'; // Cyan
    if (profitMargin >= 10) return '#ffc107'; // Yellow
    if (profitMargin >= 0) return '#fd7e14'; // Orange
    return '#dc3545'; // Red
  }
}
