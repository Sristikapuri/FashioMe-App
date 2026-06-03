import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class LocalDatabaseFailure extends Failure {
  const LocalDatabaseFailure({
    String message = 'Local database operation failure',
  }) : super(message);
}

class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure({this.statusCode, required String message}) : super(message);

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message);
}
