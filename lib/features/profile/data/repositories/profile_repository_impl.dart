import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/event_history_item.dart';
import '../../domain/entities/github_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/github_datasource.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource, this._githubDataSource);

  final ProfileRemoteDataSource _dataSource;
  final GithubDataSource _githubDataSource;

  @override
  Future<Result<AppUser>> updateProfile(AppUser user) async {
    try {
      final model = AppUserModel(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        program: user.program,
        yearLevel: user.yearLevel,
        contactNumber: user.contactNumber,
        skills: user.skills,
        githubUsername: user.githubUsername,
        linkedinUrl: user.linkedinUrl,
      );
      final updated = await _dataSource.updateProfile(user.id, model.toUpdateMap());
      return Result.success(updated);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<EventHistoryItem>>> getEventHistory(String userId) async {
    try {
      return Result.success(await _dataSource.getEventHistory(userId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<GithubStats>> syncGithubProfile({required String userId, required String username}) async {
    try {
      return Result.success(await _githubDataSource.fetchAndCache(userId: userId, username: username));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Result<GithubStats?>> getCachedGithubProfile(String userId) async {
    try {
      return Result.success(await _githubDataSource.getCached(userId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
