import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String? customCategory;
  final String? description; // What was bought
  final DateTime date;
  final String? batchId; // Optional link to batch
  final String? groupId;
  final String? groupTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    this.customCategory,
    this.description,
    required this.date,
    this.batchId,
    this.groupId,
    this.groupTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? customCategory,
    String? description,
    DateTime? date,
    String? batchId,
    String? groupId,
    String? groupTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      description: description ?? this.description,
      date: date ?? this.date,
      batchId: batchId ?? this.batchId,
      groupId: groupId ?? this.groupId,
      groupTitle: groupTitle ?? this.groupTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        currency,
        category,
        customCategory,
        description,
        date,
        batchId,
        groupId,
        groupTitle,
        createdAt,
        updatedAt,
      ];
}

enum ExpenseCategory {
  feed,
  birds,
  medicine,
  equipment,
  utilities,
  labor,
  transportation,
  maintenance,
  marketing,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
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

  String get icon {
    switch (this) {
      case ExpenseCategory.feed:
        return '🌾';
      case ExpenseCategory.birds:
        return '🐔';
      case ExpenseCategory.medicine:
        return '💊';
      case ExpenseCategory.equipment:
        return '🔧';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.labor:
        return '👷';
      case ExpenseCategory.transportation:
        return '🚚';
      case ExpenseCategory.maintenance:
        return '🔨';
      case ExpenseCategory.marketing:
        return '📢';
      case ExpenseCategory.other:
        return '📦';
    }
  }
}
