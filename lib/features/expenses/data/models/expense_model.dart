import '../../domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.currency,
    required super.category,
    super.customCategory,
    super.description,
    required super.date,
    super.batchId,
    super.groupId,
    super.groupTitle,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      customCategory: json['custom_category'] as String?,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      batchId: json['batch_id'] as String?,
      groupId: json['group_id'] as String?,
      groupTitle: json['group_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'custom_category': customCategory,
      'description': description,
      'date': date.toIso8601String(),
      'batch_id': batchId,
      'group_id': groupId,
      'group_title': groupTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      customCategory: expense.customCategory,
      description: expense.description,
      date: expense.date,
      batchId: expense.batchId,
      groupId: expense.groupId,
      groupTitle: expense.groupTitle,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
