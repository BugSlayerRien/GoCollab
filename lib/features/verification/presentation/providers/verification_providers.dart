import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/domain/entities/verification_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/verification_remote_datasource.dart';
import '../../data/repositories/verification_repository_impl.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';

final verificationRemoteDataSourceProvider = Provider<VerificationRemoteDataSource>((ref) {
  return VerificationRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(storageServiceProvider),
  );
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepositoryImpl(ref.watch(verificationRemoteDataSourceProvider));
});

/// The current user's latest submission, if any.
final myVerificationRequestProvider = FutureProvider.autoDispose<VerificationRequest?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final result = await ref.watch(verificationRepositoryProvider).getMyRequest(user.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// The status to actually show the user. `profiles.verification_status`
/// never holds "pending" — that state is derived from an open request.
final effectiveVerificationStatusProvider = Provider.autoDispose<VerificationStatus>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return VerificationStatus.unverified;
  if (user.isVerified) return VerificationStatus.verified;

  final request = ref.watch(myVerificationRequestProvider).valueOrNull;
  if (request != null && request.isPending) return VerificationStatus.pending;

  return user.verificationStatus;
});

/// Officer review queue.
final pendingVerificationRequestsProvider =
    FutureProvider.autoDispose<List<VerificationRequest>>((ref) async {
  final result = await ref.watch(verificationRepositoryProvider).getPendingRequests();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// Signed URL for one submitted ID photo. Short-lived by design, so this is
/// fetched per request row at render time rather than cached broadly.
final verificationDocumentUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) async {
  final result = await ref.watch(verificationRepositoryProvider).signedDocumentUrl(path);
  return result.when(success: (url) => url, failure: (f) => throw f);
});

class VerificationActionsController extends StateNotifier<bool> {
  VerificationActionsController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> submit({required String studentNumber, required XFile idDocument}) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final result = await _ref.read(verificationRepositoryProvider).submitRequest(
          userId: user.id,
          studentNumber: studentNumber,
          idDocument: idDocument,
        );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(myVerificationRequestProvider);
      _ref.invalidate(pendingVerificationRequestsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> review({required String requestId, required bool approve, String? reason}) async {
    state = true;
    final result = await _ref.read(verificationRepositoryProvider).review(
          requestId: requestId,
          approve: approve,
          reason: reason,
        );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(pendingVerificationRequestsProvider);
      _ref.invalidate(currentUserProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final verificationActionsControllerProvider =
    StateNotifierProvider<VerificationActionsController, bool>(
  (ref) => VerificationActionsController(ref),
);
