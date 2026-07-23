import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Each use case wraps exactly one business action and depends only on the
/// [AuthRepository] abstraction — never on Supabase types directly. This is
/// the layer the presentation controllers call into, keeping UI code free
/// of any data-layer knowledge (SOLID: single responsibility + dependency
/// inversion).
class SignInWithEmailPasswordUseCase {
  const SignInWithEmailPasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call({required String email, required String password}) {
    return _repository.signInWithEmailPassword(email: email, password: password);
  }
}

class SignUpWithEmailPasswordUseCase {
  const SignUpWithEmailPasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repository.signUpWithEmailPassword(email: email, password: password, fullName: fullName);
  }
}

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call() => _repository.signInWithGoogle();
}

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call(String email) => _repository.sendPasswordResetEmail(email);
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
