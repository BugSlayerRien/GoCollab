import '../../../../core/utils/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/event_history_item.dart';
import '../entities/github_stats.dart';

abstract class ProfileRepository {
  Future<Result<AppUser>> updateProfile(AppUser user);

  Future<Result<List<EventHistoryItem>>> getEventHistory(String userId);

  Future<Result<GithubStats>> syncGithubProfile({required String userId, required String username});

  Future<Result<GithubStats?>> getCachedGithubProfile(String userId);
}
