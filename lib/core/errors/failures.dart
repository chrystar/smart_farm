import '../utils/error_message_helper.dart';

abstract class Failure {
  final String message;

  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure(String message) 
      : super(ErrorMessageHelper.getUserFriendlyMessage(message));
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) 
      : super(ErrorMessageHelper.getUserFriendlyMessage(message));
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  CacheFailure(String message) : super(message);
} 