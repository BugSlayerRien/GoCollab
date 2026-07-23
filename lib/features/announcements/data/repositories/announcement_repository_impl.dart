import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_datasource.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._dataSource);

  final AnnouncementRemoteDataSource _dataSource;

  @override
  Future<Result<List<Announcement>>> getAnnouncements() async {
    try {
      return Result.success(await _dataSource.getAnnouncements());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createAnnouncement({
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
    required String createdBy,
  }) async {
    try {
      await _dataSource.createAnnouncement(
        title: title,
        body: body,
        category: category,
        isPinned: isPinned,
        createdBy: createdBy,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
