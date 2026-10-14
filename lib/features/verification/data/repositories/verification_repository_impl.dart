import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_datasource.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._dataSource);

  final VerificationRemoteDataSource _dataSource;

  @override
  Future<Result<VerificationRequest?>> getMyRequest(String userId) async {
    try {
      return Result.success(await _dataSource.getMyRequest(userId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> submitRequest({
    required String userId,
    required String studentNumber,
    required XFile idDocument,
    String ocrResult = 'not_run',
  }) async {
    try {
      await _dataSource.submitRequest(
        userId: userId,
        studentNumber: studentNumber,
        idDocument: idDocument,
        ocrResult: ocrResult,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<VerificationRequest>>> getPendingRequests() async {
    try {
      return Result.success(await _dataSource.getPendingRequests());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> review({
    required String requestId,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _dataSource.review(requestId: requestId, approve: approve, reason: reason);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> signedDocumentUrl(String path) async {
    try {
      return Result.success(await _dataSource.signedDocumentUrl(path));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
