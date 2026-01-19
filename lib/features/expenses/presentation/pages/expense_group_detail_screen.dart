import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/expense.dart';
import '../provider/expense_provider.dart';

class ExpenseGroupDetailScreen extends StatelessWidget {
  final String groupTitle;
  final String? groupId;

  const ExpenseGroupDetailScreen({
    super.key,
    required this.groupTitle,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expenses
        .where((e) => e.groupTitle == groupTitle && e.groupId == groupId)
        .toList();

    if (expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(groupTitle),
          centerTitle: true,
        ),
        body: const Center(child: Text('No expenses in this group yet')),
      );
    }

    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currency = expenses.first.currency;

    // Group expenses by date for display
    final groupedByDate = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      groupedByDate.putIfAbsent(dateKey, () => []).add(expense);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(groupTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add expense to group',
            onPressed: () => _showAddExpenseSheet(context, expenses),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currency ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${expenses.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'expense${expenses.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expenses List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final dayExpenses = groupedByDate[date]!;
                final dayTotal = dayExpenses.fold<double>(
                  0,
                  (sum, e) => sum + e.amount,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: $currency ${dayTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expense Cards
                    ...dayExpenses.map((expense) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 0,
                        child: GestureDetector(
                          onTap: () => _showExpenseDetails(context, expense),
                          child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.1),
                            child: Text(
                              expense.category.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.category.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (expense.description != null &&
                                  expense.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    expense.description!,
                                    style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                NumberFormat.currency(
                                        symbol: expense.currency + ' ')
                                    .format(expense.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.redAccent),
                                tooltip: 'Remove from group',
                                onPressed: () => _removeExpenseFromGroup(
                                  context,
                                  expense.id,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, List<Expense> currentExpenses) {
    final provider = context.read<ExpenseProvider>();
    final ungrouped = provider.expenses.where((e) => e.groupId == null && e.groupTitle == null).toList();
    final resolvedGroupId = groupId ?? (currentExpenses.isNotEmpty ? currentExpenses.first.groupId : null);

    if (resolvedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group information not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add expense to "$groupTitle"',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ungrouped.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No ungrouped expenses available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  ...ungrouped.map(
                    (expense) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(expense.category.icon),
                      ),
                      title: Text(expense.description?.isNotEmpty == true
                          ? expense.description!
                          : expense.category.displayName),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date)),
                      trailing: Text(
                        NumberFormat.currency(symbol: '${expense.currency} ').format(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final success = await provider.addExpenseToGroup(
                          expenseId: expense.id,
                          groupId: resolvedGroupId,
                          groupTitle: groupTitle,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Added to group'
                                : provider.errorMessage ?? 'Failed to add expense'),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeExpenseFromGroup(BuildContext context, String expenseId) async {
    final provider = context.read<ExpenseProvider>();
    final success = await provider.removeExpenseFromGroup(expenseId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Removed from group'
            : provider.errorMessage ?? 'Failed to remove expense'),
      ),
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(expense.category.icon,
                        style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.category.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy · h:mm a')
                              .format(expense.date),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (expense.description != null &&
                  expense.description!.isNotEmpty) ...[
                const Text('Description',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(expense.description!,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
              ],

              const Text('Amount',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                NumberFormat.currency(symbol: expense.currency + ' ')
                    .format(expense.amount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              if (expense.batchId != null) ...[
                const Text('Linked Batch',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(expense.batchId!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
}
