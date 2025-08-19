// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => message;
}

// Network related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.details,
  });
}

class LocationException extends AppException {
  const LocationException({
    required super.message,
    super.statusCode,
    super.details,
  });
}
