import 'package:equatable/equatable.dart';

/// Base type for all recoverable, user-facing error conditions. Repository
/// implementations catch raw exceptions (Supabase/Postgrest/network) and
/// translate them into one of these so the presentation layer never has to
/// know about data-layer exception types (Clean Architecture boundary).
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our end. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item could not be found.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to perform this action.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
