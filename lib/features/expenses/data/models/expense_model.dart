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
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'NGN',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      customCategory: json['custom_category']?.toString(),
      description: json['description']?.toString(),
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      batchId: json['batch_id']?.toString(),
      groupId: json['group_id']?.toString(),
      groupTitle: json['group_title']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
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
