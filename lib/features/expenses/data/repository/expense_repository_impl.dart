import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repository/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Expense>>> getExpenses(String userId) async {
    try {
      final expenses = await remoteDataSource.getExpenses(userId);
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await remoteDataSource.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByBatch(
    String userId,
    String batchId,
  ) async {
    try {
      final expenses = await remoteDataSource.getExpensesByBatch(userId, batchId);
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String expenseId) async {
    try {
      final expense = await remoteDataSource.getExpenseById(expenseId);
      return Right(expense);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final created = await remoteDataSource.createExpense(expenseModel);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final updated = await remoteDataSource.updateExpense(expenseModel);
      return Right(updated);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String expenseId) async {
    try {
      await remoteDataSource.deleteExpense(expenseId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<ExpenseCategory, double>>> getExpensesByCategory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await remoteDataSource.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );

      final Map<ExpenseCategory, double> categoryTotals = {};
      for (final expense in expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      return Right(categoryTotals);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpenses(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await remoteDataSource.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );

      final total = expenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
