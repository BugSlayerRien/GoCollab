import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage_service.dart';
import '../models/verification_request_model.dart';

class VerificationRemoteDataSource {
  VerificationRemoteDataSource(this._client, this._storage);

  final SupabaseClient _client;
  final StorageService _storage;

  static const _requestSelect =
      '*, applicant:profiles!verification_requests_user_id_fkey(id, full_name, avatar_url)';

  Future<VerificationRequestModel?> getMyRequest(String userId) async {
    final row = await _client
        .from('verification_requests')
        .select(_requestSelect)
        .eq('user_id', userId)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return VerificationRequestModel.fromMap(row);
  }

  Future<void> submitRequest({
    required String userId,
    required String studentNumber,
    required XFile idDocument,
  }) async {
    final objectPath = await _storage.uploadVerificationDocument(file: idDocument, userId: userId);

    await _client.from('verification_requests').insert({
      'user_id': userId,
      'student_number': studentNumber,
      'id_document_path': objectPath,
      'status': 'pending',
    });
  }

  Future<List<VerificationRequestModel>> getPendingRequests() async {
    final rows = await _client
        .from('verification_requests')
        .select(_requestSelect)
        .eq('status', 'pending')
        .order('submitted_at');
    return (rows as List)
        .map((r) => VerificationRequestModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Officer decision. The RPC is SECURITY DEFINER and re-checks
  /// `is_officer()` server-side, so this cannot be forged by a member.
  Future<void> review({required String requestId, required bool approve, String? reason}) async {
    await _client.rpc('review_verification_request', params: {
      'p_request_id': requestId,
      'p_approve': approve,
      'p_reason': reason,
    });
  }

  Future<String> signedDocumentUrl(String path) => _storage.signedVerificationDocumentUrl(path);
}
