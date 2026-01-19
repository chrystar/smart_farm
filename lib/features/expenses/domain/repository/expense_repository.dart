import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses(String userId);
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<Expense>>> getExpensesByBatch(
    String userId,
    String batchId,
  );
  Future<Either<Failure, Expense>> getExpenseById(String expenseId);
  Future<Either<Failure, Expense>> createExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String expenseId);
  Future<Either<Failure, Map<ExpenseCategory, double>>> getExpensesByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, double>> getTotalExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}
