import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/github_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/event_history_item.dart';
import '../../domain/entities/github_stats.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(supabaseClientProvider));
});

final githubDataSourceProvider = Provider<GithubDataSource>((ref) {
  return GithubDataSource(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider), ref.watch(githubDataSourceProvider));
});

final eventHistoryProvider = FutureProvider.autoDispose<List<EventHistoryItem>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getEventHistory(user.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final cachedGithubProfileProvider = FutureProvider.autoDispose<GithubStats?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final repository = ref.watch(profileRepositoryProvider);
  final result = await repository.getCachedGithubProfile(user.id);
  return result.when(success: (data) => data, failure: (_) => null);
});

class ProfileEditController extends StateNotifier<AsyncValue<void>> {
  ProfileEditController(this._ref) : super(const AsyncValue.data(null));
  final Ref _ref;

  Future<bool> save(AppUser updated) async {
    state = const AsyncValue.loading();
    final repository = _ref.read(profileRepositoryProvider);
    final result = await repository.updateProfile(updated);
    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        return true;
      },
      failure: (f) {
        state = AsyncValue.error(f, StackTrace.current);
        return false;
      },
    );
  }

  Future<GithubStats?> syncGithub({required String userId, required String username}) async {
    final repository = _ref.read(profileRepositoryProvider);
    final result = await repository.syncGithubProfile(userId: userId, username: username);
    _ref.invalidate(cachedGithubProfileProvider);
    return result.dataOrNull;
  }
}

final profileEditControllerProvider =
    StateNotifierProvider.autoDispose<ProfileEditController, AsyncValue<void>>((ref) => ProfileEditController(ref));
