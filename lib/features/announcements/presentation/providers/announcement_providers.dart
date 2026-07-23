import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../data/datasources/announcement_remote_datasource.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

final announcementRemoteDataSourceProvider = Provider<AnnouncementRemoteDataSource>((ref) {
  return AnnouncementRemoteDataSource(ref.watch(supabaseClientProvider));
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(ref.watch(announcementRemoteDataSourceProvider));
});

final announcementsListProvider = FutureProvider.autoDispose<List<Announcement>>((ref) async {
  final repository = ref.watch(announcementRepositoryProvider);
  final result = await repository.getAnnouncements();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

class AnnouncementController extends StateNotifier<bool> {
  AnnouncementController(this._ref) : super(false);
  final Ref _ref;

  Future<bool> create({
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
    required String createdBy,
  }) async {
    state = true;
    final repository = _ref.read(announcementRepositoryProvider);
    final result = await repository.createAnnouncement(
      title: title,
      body: body,
      category: category,
      isPinned: isPinned,
      createdBy: createdBy,
    );
    state = false;
    if (result.isSuccess) _ref.invalidate(announcementsListProvider);
    return result.isSuccess;
  }
}

final announcementControllerProvider =
    StateNotifierProvider.autoDispose<AnnouncementController, bool>((ref) => AnnouncementController(ref));
