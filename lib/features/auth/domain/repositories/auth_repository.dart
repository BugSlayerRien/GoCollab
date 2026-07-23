import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';

/// Contract the presentation layer depends on. The data layer provides the
/// concrete Supabase-backed implementation (`AuthRepositoryImpl`) — this
/// abstraction is what makes the domain/presentation layers unit-testable
/// without touching the network.
abstract class AuthRepository {
  /// Emits the current [AppUser] (or `null` when signed out) every time the
  /// Supabase auth session changes.
  Stream<AppUser?> watchCurrentUser();

  Future<AppUser?> getCurrentUser();

  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Result<AppUser>> signInWithGoogle();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> updatePassword(String newPassword);

  Future<Result<void>> signOut();
}
