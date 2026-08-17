import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
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

  Future<String?> create({
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
    if (result.isSuccess) {
      _ref.invalidate(announcementsListProvider);
      _ref.invalidate(notificationsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> update({
    required String id,
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
  }) async {
    state = true;
    final repository = _ref.read(announcementRepositoryProvider);
    final result = await repository.updateAnnouncement(
      id: id,
      title: title,
      body: body,
      category: category,
      isPinned: isPinned,
    );
    state = false;
    if (result.isSuccess) _ref.invalidate(announcementsListProvider);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> delete(String id) async {
    final repository = _ref.read(announcementRepositoryProvider);
    final result = await repository.deleteAnnouncement(id);
    if (result.isSuccess) _ref.invalidate(announcementsListProvider);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final announcementControllerProvider =
    StateNotifierProvider<AnnouncementController, bool>((ref) => AnnouncementController(ref));
