import '../../../../core/utils/result.dart';
import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<Result<List<Announcement>>> getAnnouncements();

  Future<Result<void>> createAnnouncement({
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
    required String createdBy,
  });

  Future<Result<void>> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
  });

  Future<Result<void>> deleteAnnouncement(String id);
}
