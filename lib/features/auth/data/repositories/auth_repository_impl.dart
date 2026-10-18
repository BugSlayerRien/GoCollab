import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    // Subscribe BEFORE the first (slow) profile fetch. On a cold start from the
    // OAuth redirect the sign-in event can arrive while that fetch is still
    // running; a late subscription would miss it and leave the user on the
    // login screen. A plain StreamController buffers until we start reading.
    final buffered = StreamController<AuthState>();
    final subscription = _dataSource.onAuthStateChange.listen(buffered.add);
    try {
      // Emit any session established during startup (e.g. PKCE callback).
      yield await getCurrentUser();

      await for (final state in buffered.stream) {
        final user = state.session?.user;
        debugPrint('[Auth] ${state.event.name} user=${user?.id}');
        if (user == null) {
          yield null;
          continue;
        }
        yield await _fetchProfileWithRetry(user.id);
      }
    } finally {
      await subscription.cancel();
      await buffered.close();
    }
  }

  Future<AppUser?> _fetchProfileWithRetry(String userId) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final profile = await _dataSource.fetchProfile(userId);
        if (profile != null) return profile;
      } catch (e) {
        debugPrint('[Auth] profile fetch failed (attempt ${attempt + 1}): $e');
      }
      // the profile row is created by a database trigger; give it a moment
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    return null;
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
  Future<Result<void>> signInWithGoogle() async {
    try {
      await _dataSource.signInWithGoogle();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> requestGoogleCalendarAccess() async {
    try {
      await _dataSource.requestGoogleCalendarAccess();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetOtp(String email) async {
    try {
      await _dataSource.sendPasswordResetOtp(email);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> verifyPasswordOtp({required String email, required String token}) async {
    try {
      await _dataSource.verifyPasswordOtp(email: email, token: token);
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
