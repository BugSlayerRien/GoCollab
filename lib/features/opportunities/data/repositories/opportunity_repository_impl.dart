import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';
import '../datasources/opportunity_remote_datasource.dart';

class OpportunityRepositoryImpl implements OpportunityRepository {
  OpportunityRepositoryImpl(this._dataSource);

  final OpportunityRemoteDataSource _dataSource;

  @override
  Future<Result<List<Opportunity>>> getOpportunities({String? currentUserId}) async {
    try {
      return Result.success(await _dataSource.getOpportunities(currentUserId: currentUserId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Opportunity>> getOpportunityById(String id, {String? currentUserId}) async {
    try {
      return Result.success(await _dataSource.getOpportunityById(id, currentUserId: currentUserId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> toggleSaved({
    required String opportunityId,
    required String userId,
    required bool save,
  }) async {
    try {
      await _dataSource.toggleSaved(opportunityId: opportunityId, userId: userId, save: save);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Opportunity>>> getSavedOpportunities(String userId) async {
    try {
      return Result.success(await _dataSource.getSavedOpportunities(userId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createOpportunity({
    required String title,
    required String organization,
    required OpportunityType type,
    required String description,
    String? requirements,
    String? location,
    required bool isRemote,
    String? applicationUrl,
    DateTime? deadline,
    required String postedBy,
  }) async {
    try {
      await _dataSource.createOpportunity(
        title: title,
        organization: organization,
        type: type,
        description: description,
        requirements: requirements,
        location: location,
        isRemote: isRemote,
        applicationUrl: applicationUrl,
        deadline: deadline,
        postedBy: postedBy,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
