import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/features/expenses/domain/entities/expense.dart';
import 'package:smart_farm/features/expenses/presentation/provider/expense_provider.dart';
import '../../../../core/services/supabase_service.dart';

import 'add_expense_screen.dart';
import 'expense_dashboard_screen.dart';
import 'expense_group_detail_screen.dart';
import '../services/expense_report_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedExpenseIds = {};
  int _selectedTab = 0; // 0: All, 1: Grouped, 2: Ungrouped

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenses();
    });
  }

  void _loadExpenses() {
    final userId = SupabaseService().currentUserId;
    if (userId != null) {
      context.read<ExpenseProvider>().loadExpenses(userId);
    }
  }

  Widget _buildTabButton(String label, int tabIndex) {
    final isSelected = _selectedTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _generateReportForExpenses(
    BuildContext context,
    List<Expense> expenses,
  ) async {
    if (expenses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to generate report')),
      );
      return;
    }

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get date range from expenses
      final dates = expenses.map((e) => e.date).toList()..sort();
      final dateRange = DateTimeRange(
        start: dates.first,
        end: dates.last,
      );

      // Generate PDF
      final pdfFile = await ExpenseReportService.generatePdfReport(
        expenses: expenses,
        dateRange: dateRange,
        categoryBreakdown: context.read<ExpenseProvider>().getExpensesByCategory(),
        totalAmount:
            expenses.fold<double>(0, (sum, e) => sum + e.amount),
      );

      // Close loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Get the button's position for iPad share sheet
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final Rect sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 10, 10);

      // Share PDF
      await ExpenseReportService.shareReport(
        pdfFile,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      // Try to close dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<void> _showExportPicker() async {
    final provider = context.read<ExpenseProvider>();
    final groupedTitles = provider.expenses
        .where((e) => e.groupTitle != null)
        .map((e) => e.groupTitle!)
        .toSet()
        .toList()
      ..sort();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Export Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('All expenses'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _generateReportForExpenses(context, provider.expenses);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text('Ungrouped expenses'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final ungrouped =
                        provider.expenses.where((e) => e.groupTitle == null).toList();
                    _generateReportForExpenses(context, ungrouped);
                  },
                ),
                ExpansionTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Grouped expenses'),
                  children: groupedTitles.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 12),
                            child: Text(
                              'No groups available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ]
                      : groupedTitles
                          .map(
                            (title) => ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(title),
                              subtitle: Text(
                                '${provider.expenses.where((e) => e.groupTitle == title).length} item(s)',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                final grouped = provider.expenses
                                    .where((e) => e.groupTitle == title)
                                    .toList();
                                _generateReportForExpenses(context, grouped);
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ExpenseProvider>();
      final success = await provider.deleteExpense(expenseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Expense deleted successfully'
                  : provider.errorMessage ?? 'Failed to delete expense',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_selectedExpenseIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 expenses to group'),
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
                '${_selectedExpenseIds.length} expenses selected',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Group Title',
                  hintText: 'e.g., Week 1 Expenses, Feed Purchases',
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
      final provider = context.read<ExpenseProvider>();
      final success = await provider.createExpenseGroup(
        groupTitle,
        _selectedExpenseIds.toList(),
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
            _selectedExpenseIds.clear();
          });
          _loadExpenses();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedExpenseIds.length} selected'
            : 'Expenses'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedExpenseIds.clear();
                  });
                },
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      final provider = context.read<ExpenseProvider>();
                      if (_selectedExpenseIds.length ==
                          provider.filteredExpenses.length) {
                        _selectedExpenseIds.clear();
                      } else {
                        _selectedExpenseIds.addAll(
                          provider.filteredExpenses.map((e) => e.id),
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
                  icon: const Icon(Icons.analytics),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExpenseDashboardScreen(),
                      ),
                    );
                  },
                  tooltip: 'View Analytics',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: _showExportPicker,
                  tooltip: 'Generate Report',
                ),
              ],
      ),
      body: Consumer<ExpenseProvider>(
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
                    onPressed: _loadExpenses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => provider.clearSearch(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Tab Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildTabButton('All', 0),
                          const SizedBox(width: 12),
                          _buildTabButton('Grouped', 1),
                          const SizedBox(width: 12),
                          _buildTabButton('Ungrouped', 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Expenses List
              Expanded(
                child: provider.filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No Expenses Found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.searchQuery.isNotEmpty
                                  ? 'No expenses match your search'
                                  : 'Tap + to add your first expense',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : _buildExpensesList(provider, _selectedTab),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          _loadExpenses();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final isSelected = _selectedExpenseIds.contains(expense.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedExpenseIds.remove(expense.id);
              } else {
                _selectedExpenseIds.add(expense.id);
              }
            });
          } else {
            _showExpenseDetails(expense);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedExpenseIds.add(expense.id);
            });
          }
        },
        child: ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedExpenseIds.remove(expense.id);
                      } else {
                        _selectedExpenseIds.add(expense.id);
                      }
                    });
                  },
                )
              : CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (expense.description != null &&
                  expense.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    expense.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            DateFormat('MMM dd, yyyy').format(expense.createdAt),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: expense.currency + ' ')
                        .format(expense.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteExpense(expense.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
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

  Widget _buildExpensesList(ExpenseProvider provider, int selectedTab) {
    // Group expenses by groupTitle
    final Map<String?, List<Expense>> groupedByTitle = {};
    for (final expense in provider.filteredExpenses) {
      groupedByTitle.putIfAbsent(expense.groupTitle, () => []).add(expense);
    }

    final ungroupedExpenses = groupedByTitle[null] ?? [];
    final groupedEntries = groupedByTitle.entries
        .where((entry) => entry.key != null)
        .toList()
      ..sort((a, b) => b.value.first.date.compareTo(a.value.first.date));

    if (selectedTab == 0) {
      // All tab: show all as flat list
      return _buildFlatExpensesList(provider.filteredExpenses);
    } else if (selectedTab == 1) {
      // Grouped tab: show only group cards
      return _buildGroupedExpensesList(groupedEntries);
    } else {
      // Ungrouped tab: show ungrouped by date
      return _buildUngroupedExpensesList(ungroupedExpenses);
    }
  }

  Widget _buildFlatExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadExpenses(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No Expenses Found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first expense',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by date
    final groupedByDate = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      groupedByDate.putIfAbsent(dateKey, () => []).add(expense);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async => _loadExpenses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
              // Date Divider Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Total: ${dayExpenses.first.currency} ${dayTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Expense Cards for this date
              ...dayExpenses.map((expense) => _buildExpenseCard(expense)),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedExpensesList(
      List<MapEntry<String?, List<Expense>>> groupedEntries) {
    if (groupedEntries.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadExpenses(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_outlined,
                  size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No Grouped Expenses',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Long-press expenses and create a group',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadExpenses(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: groupedEntries
            .map((entry) => _buildGroupCard(
                  groupTitle: entry.key!,
                  expenses: entry.value,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildGroupCard({
    required String groupTitle,
    required List<Expense> expenses,
  }) {
    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currency = expenses.first.currency;
    final groupId = expenses.first.groupId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseGroupDetailScreen(
              groupTitle: groupTitle,
              groupId: groupId,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        groupTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expenses.length} expense${expenses.length > 1 ? 's' : ''}',
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
                      '$currency ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUngroupedExpensesList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _loadExpenses(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No Ungrouped Expenses',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All expenses are grouped!',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadExpenses(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildUngroupedExpensesByDate(expenses),
      ),
    );
  }

  List<Widget> _buildUngroupedExpensesByDate(List<Expense> expenses) {
    // Group ungrouped expenses by date
    final groupedExpenses = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      groupedExpenses.putIfAbsent(dateKey, () => []).add(expense);
    }

    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDates.expand((date) {
      final dayExpenses = groupedExpenses[date]!;
      final dayTotal = dayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return [
        // Date Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${NumberFormat.currency(symbol: dayExpenses.first.currency + ' ').format(dayTotal)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        // Expense Cards
        ...dayExpenses.map((expense) => _buildExpenseCard(expense)),
        const SizedBox(height: 16),
      ];
    }).toList();
  }
}

