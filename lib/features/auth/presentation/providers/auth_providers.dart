import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/services/google_token_storage.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signInUseCaseProvider = Provider((ref) => SignInWithEmailPasswordUseCase(ref.watch(authRepositoryProvider)));
final signUpUseCaseProvider = Provider((ref) => SignUpWithEmailPasswordUseCase(ref.watch(authRepositoryProvider)));
final signInWithGoogleUseCaseProvider =
    Provider((ref) => SignInWithGoogleUseCase(ref.watch(authRepositoryProvider)));
final requestGoogleCalendarAccessUseCaseProvider =
    Provider((ref) => RequestGoogleCalendarAccessUseCase(ref.watch(authRepositoryProvider)));
final sendPasswordResetOtpUseCaseProvider =
    Provider((ref) => SendPasswordResetOtpUseCase(ref.watch(authRepositoryProvider)));
final verifyPasswordOtpUseCaseProvider =
    Provider((ref) => VerifyPasswordOtpUseCase(ref.watch(authRepositoryProvider)));
final updatePasswordUseCaseProvider =
    Provider((ref) => UpdatePasswordUseCase(ref.watch(authRepositoryProvider)));
final signOutUseCaseProvider = Provider((ref) => SignOutUseCase(ref.watch(authRepositoryProvider)));

/// Tracks whether the current session was established via a password recovery
/// link. When true, the router sends the user to `/reset-password` instead of
/// the main shell so they can set a new password before proceeding.
final isPasswordRecoveryProvider =
    StateProvider<bool>((ref) => SupabaseService.pendingPasswordRecovery);

/// Listens for Supabase PASSWORD_RECOVERY auth events (triggered when the
/// user clicks the magic link in the reset email).
final passwordRecoveryListenerProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      ref.read(isPasswordRecoveryProvider.notifier).state = true;
    }
  });
});

/// Persists Google provider tokens whenever Supabase returns them.
final googleTokenListenerProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);
  client.auth.onAuthStateChange.listen((data) async {
    final session = data.session;
    if (session == null) return;
    if (data.event == AuthChangeEvent.signedIn ||
        data.event == AuthChangeEvent.tokenRefreshed ||
        data.event == AuthChangeEvent.initialSession) {
      await GoogleTokenStorage.saveFromSession(session);
    }
  });
});

/// Live, app-wide session stream. The router watches this to decide between
/// the auth flow, member shell, and officer shell.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.watchCurrentUser().distinct();
});

/// Transient UI state for the login/register/forgot-password forms.
class AuthFormState {
  const AuthFormState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;

  AuthFormState copyWith({bool? isSubmitting, String? errorMessage}) {
    return AuthFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class AuthFormController extends StateNotifier<AuthFormState> {
  AuthFormController(this._ref) : super(const AuthFormState());

  final Ref _ref;

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(signInUseCaseProvider);
    final result = await useCase(email: email, password: password);
    return _handle(result);
  }

  Future<bool> signUp({required String email, required String password, required String fullName}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(signUpUseCaseProvider);
    final result = await useCase(email: email, password: password, fullName: fullName);
    return _handle(result);
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(signInWithGoogleUseCaseProvider);
    final result = await useCase();
    return _handle(result);
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(sendPasswordResetOtpUseCaseProvider);
    final result = await useCase(email);
    return _handle(result);
  }

  Future<bool> verifyPasswordOtp({required String email, required String token}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(verifyPasswordOtpUseCaseProvider);
    final result = await useCase(email: email, token: token);
    return _handle(result);
  }

  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(updatePasswordUseCaseProvider);
    final result = await useCase(newPassword);
    return _handle(result);
  }

  bool _handle(Result<Object?> result) {
    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false, errorMessage: null);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final authFormControllerProvider = StateNotifierProvider.autoDispose<AuthFormController, AuthFormState>(
  (ref) => AuthFormController(ref),
);
