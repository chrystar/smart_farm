import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repository/expense_repository.dart';

class CreateExpenseUseCase {
  final ExpenseRepository repository;

  CreateExpenseUseCase(this.repository);

  Future<Either<Failure, Expense>> call(Expense expense) {
    return repository.createExpense(expense);
  }
}
