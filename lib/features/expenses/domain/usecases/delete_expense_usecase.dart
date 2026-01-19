import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repository/expense_repository.dart';

class DeleteExpenseUseCase {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<Either<Failure, void>> call(String expenseId) {
    return repository.deleteExpense(expenseId);
  }
}
