class LocalDatabaseException implements Exception {
  final String message;

  LocalDatabaseException({this.message = 'Local database error'});
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});
}
