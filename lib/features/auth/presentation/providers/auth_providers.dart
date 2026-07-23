import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
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
final sendPasswordResetUseCaseProvider =
    Provider((ref) => SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider)));
final signOutUseCaseProvider = Provider((ref) => SignOutUseCase(ref.watch(authRepositoryProvider)));

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

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final useCase = _ref.read(sendPasswordResetUseCaseProvider);
    final result = await useCase(email);
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
