import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/application_claim.dart';

const _claimSelect = '*, applicant:profiles!application_claims_user_id_fkey(id, full_name, avatar_url), '
    'opportunity:opportunities!application_claims_opportunity_id_fkey(title, organization)';

/// The signed-in member's claim for one opportunity, if they've tapped Apply.
final myClaimProvider = FutureProvider.autoDispose.family<ApplicationClaim?, String>((ref, opportunityId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('application_claims')
      .select(_claimSelect)
      .eq('user_id', user.id)
      .eq('opportunity_id', opportunityId)
      .maybeSingle();
  return row == null ? null : ApplicationClaim.fromMap(row);
});

/// Officer queue.
final pendingClaimsProvider = FutureProvider.autoDispose<List<ApplicationClaim>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('application_claims')
      .select(_claimSelect)
      .eq('status', 'pending')
      .order('submitted_at');
  return (rows as List).map((r) => ApplicationClaim.fromMap(r as Map<String, dynamic>)).toList();
});

final claimProofUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, path) {
  return ref.watch(storageServiceProvider).signedApplicationProofUrl(path);
});

class ClaimActionsController extends StateNotifier<bool> {
  ClaimActionsController(this._ref) : super(false);
  final Ref _ref;

  /// Server-timestamped record that the member tapped "Apply now". Never
  /// blocks or fails the apply itself.
  Future<void> recordClick(String opportunityId) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await _ref.read(supabaseClientProvider).from('application_claims').upsert(
        {'user_id': user.id, 'opportunity_id': opportunityId, 'status': 'clicked'},
        onConflict: 'user_id,opportunity_id',
        ignoreDuplicates: true,
      );
      _ref.invalidate(myClaimProvider(opportunityId));
    } catch (_) {}
  }

  Future<String?> submitProof(String opportunityId, XFile proof) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    try {
      final path = await _ref.read(storageServiceProvider).uploadApplicationProof(file: proof, userId: user.id);
      await _ref.read(supabaseClientProvider).rpc('submit_application_proof', params: {
        'p_opportunity_id': opportunityId,
        'p_proof_path': path,
      });
      _ref.invalidate(myClaimProvider(opportunityId));
      _ref.invalidate(pendingClaimsProvider);
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  Future<String?> review(String claimId, {required bool approve, String? reason}) async {
    state = true;
    try {
      await _ref.read(supabaseClientProvider).rpc('review_application_claim', params: {
        'p_claim_id': claimId,
        'p_approve': approve,
        'p_reason': reason,
      });
      _ref.invalidate(pendingClaimsProvider);
      _ref.invalidate(communityPointsProvider);
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }
}

final claimActionsControllerProvider =
    StateNotifierProvider<ClaimActionsController, bool>((ref) => ClaimActionsController(ref));
