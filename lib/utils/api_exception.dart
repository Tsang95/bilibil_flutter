enum ApiExceptionType {
  cancelled,
  connection,
  timeout,
  unauthorized,
  business,
  parsing,
  unknown,
}

final class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}
