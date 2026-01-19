import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repository/expense_repository.dart';

class GetExpensesByDateRangeUseCase {
  final ExpenseRepository repository;

  GetExpensesByDateRangeUseCase(this.repository);

  Future<Either<Failure, List<Expense>>> call(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return repository.getExpensesByDateRange(userId, startDate, endDate);
  }
}
