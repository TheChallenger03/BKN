  abstract class Failure {
  final String message;
  
  const Failure(this.message);
  
  @override
  String toString() => message;
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Location Failures
class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure(super.message);
}

class LocationServiceFailure extends Failure {
  const LocationServiceFailure(super.message);
}

class LocationNotFoundFailure extends Failure {
  const LocationNotFoundFailure(super.message);
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}