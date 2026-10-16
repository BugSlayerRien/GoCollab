import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/application_claim.dart';

const _claimSelect = '*, applicant:profiles!application_claims_user_id_fkey(id, full_name, avatar_url), '
    'opportunity:opportunities!application_claims_opportunity_id_fkey(title, organization)';

/// Max rows fetched into the review list at once. The officer works through
/// the queue in batches instead of loading thousands of rows.
const claimPageSize = 100;

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

/// Lightweight view of every pending claim (no proofs, no joins beyond the
/// title) — used for the per-opportunity counts and the dashboard badge.
typedef PendingClaimSummary = ({String id, String opportunityId, String title, String ocrResult});

final pendingClaimSummaryProvider = FutureProvider.autoDispose<List<PendingClaimSummary>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('application_claims')
      .select('id, opportunity_id, ocr_result, opportunity:opportunities!application_claims_opportunity_id_fkey(title)')
      .eq('status', 'pending');
  return (rows as List)
      .map((r) => (
            id: r['id'] as String,
            opportunityId: r['opportunity_id'] as String,
            title: ((r['opportunity'] as Map<String, dynamic>?)?['title'] as String?) ?? 'Opportunity',
            ocrResult: (r['ocr_result'] as String?) ?? 'not_run',
          ))
      .toList();
});

/// Officer queue, optionally narrowed to one opportunity. Oldest first,
/// capped at [claimPageSize] — approve a batch and the next one appears.
final pendingClaimsProvider =
    FutureProvider.autoDispose.family<List<ApplicationClaim>, String?>((ref, opportunityId) async {
  var query = ref
      .watch(supabaseClientProvider)
      .from('application_claims')
      .select(_claimSelect)
      .eq('status', 'pending');
  if (opportunityId != null) query = query.eq('opportunity_id', opportunityId);
  final rows = await query.order('submitted_at').limit(claimPageSize);
  return (rows as List).map((r) => ApplicationClaim.fromMap(r as Map<String, dynamic>)).toList();
});

final claimProofUrlProvider = FutureProvider.autoDispose.family<String, String>((ref, path) {
  return ref.watch(storageServiceProvider).signedApplicationProofUrl(path);
});

class ClaimActionsController extends StateNotifier<bool> {
  ClaimActionsController(this._ref) : super(false);
  final Ref _ref;

  void _refreshQueue() {
    _ref.invalidate(pendingClaimsProvider);
    _ref.invalidate(pendingClaimSummaryProvider);
  }

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

  Future<String?> submitProof(String opportunityId, XFile proof, {String ocrResult = 'not_run'}) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    try {
      final path = await _ref.read(storageServiceProvider).uploadApplicationProof(file: proof, userId: user.id);
      await _ref.read(supabaseClientProvider).rpc('submit_application_proof', params: {
        'p_opportunity_id': opportunityId,
        'p_proof_path': path,
        'p_ocr_result': ocrResult,
      });
      _ref.invalidate(myClaimProvider(opportunityId));
      _refreshQueue();
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
      _refreshQueue();
      _ref.invalidate(communityPointsProvider);
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  /// Approve or reject many claims in one call. Returns an error message, or
  /// null on success; [onDone] receives how many were actually processed.
  Future<String?> reviewBulk(
    List<String> claimIds, {
    required bool approve,
    String? reason,
    void Function(int count)? onDone,
  }) async {
    if (claimIds.isEmpty) return null;
    state = true;
    try {
      final count = await _ref.read(supabaseClientProvider).rpc('review_application_claims_bulk', params: {
        'p_claim_ids': claimIds,
        'p_approve': approve,
        'p_reason': reason,
      });
      onDone?.call((count as num?)?.toInt() ?? claimIds.length);
      _refreshQueue();
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
