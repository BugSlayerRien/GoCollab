import 'package:supabase_flutter/supabase_flutter.dart';
import 'failure.dart';

/// Translates raw Supabase/Postgrest exceptions into domain [Failure]s.
/// Every data-source/repository implementation should route its `catch`
/// blocks through this mapper so the presentation layer only ever deals
/// with [Failure] subtypes.
Failure mapExceptionToFailure(Object error) {
  if (error is AuthException) {
    return AuthFailure(_friendlyAuthMessage(error));
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST301' || error.code == '42501') {
      return const PermissionFailure();
    }
    if (error.code == 'PGRST116') {
      return const NotFoundFailure();
    }
    return ServerFailure(error.message);
  }
  if (error is StorageException) {
    return ServerFailure(error.message);
  }
  return const UnknownFailure();
}

String _friendlyAuthMessage(AuthException error) {
  final msg = error.message.toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (msg.contains('user already registered')) {
    return 'An account with this email already exists.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Please verify your email before signing in.';
  }
  if (msg.contains('password should be at least')) {
    return 'Password must be at least 6 characters long.';
  }
  return error.message;
}
