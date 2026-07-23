import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _dataSource.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      try {
        return await _dataSource.fetchProfile(user.id);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _dataSource.currentSupabaseUser;
    if (user == null) return null;
    try {
      return await _dataSource.fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmailPassword(email: email, password: password);
      return Result.success(user);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AppUser>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final user = await _dataSource.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      return Result.success(user);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Result.success(user);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _dataSource.updatePassword(newPassword);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
