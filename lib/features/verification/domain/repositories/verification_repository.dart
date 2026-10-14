import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/result.dart';
import '../entities/verification_request.dart';

abstract class VerificationRepository {
  /// The current user's most recent request, or null if they have never
  /// submitted one (e.g. they were auto-verified by school email).
  Future<Result<VerificationRequest?>> getMyRequest(String userId);

  /// Uploads the ID photo to the private bucket and opens a pending request.
  Future<Result<void>> submitRequest({
    required String userId,
    required String studentNumber,
    required XFile idDocument,
    String ocrResult = 'not_run',
  });

  /// Officer queue — pending requests, oldest first.
  Future<Result<List<VerificationRequest>>> getPendingRequests();

  /// Officer decision. Routed through the `review_verification_request` RPC
  /// so the request row and the member's profile move together.
  Future<Result<void>> review({
    required String requestId,
    required bool approve,
    String? reason,
  });

  /// Short-lived signed URL for an ID photo, for officer review.
  Future<Result<String>> signedDocumentUrl(String path);
}
