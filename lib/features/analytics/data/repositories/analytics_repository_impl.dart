import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/analytics_snapshot.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._dataSource);
  final AnalyticsRemoteDataSource _dataSource;

  @override
  Future<Result<AnalyticsSnapshot>> getSnapshot() async {
    try {
      return Result.success(await _dataSource.getSnapshot());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
