import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/announcement.dart';
import '../models/announcement_model.dart';

class AnnouncementRemoteDataSource {
  AnnouncementRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final rows = await _client
        .from('announcements')
        .select('*, author:profiles!announcements_created_by_fkey(full_name)')
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false);

    return (rows as List).map((row) => AnnouncementModel.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> createAnnouncement({
    required String title,
    required String body,
    required AnnouncementCategory category,
    required bool isPinned,
    required String createdBy,
  }) async {
    await _client.from('announcements').insert({
      'title': title,
      'body': body,
      'category': category.name,
      'is_pinned': isPinned,
      'created_by': createdBy,
    });
  }
}
