import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/community_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._dataSource);
  final DashboardRemoteDataSource _dataSource;

  @override
  Future<Result<CommunityStats>> getCommunityStats(String userId) async {
    try {
      return Result.success(await _dataSource.getCommunityStats(userId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
