import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_stats.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<CommunityStats> getCommunityStats(String userId) async {
    final mine = await _client.from('profiles').select('points, chapter_id').eq('id', userId).maybeSingle();
    final chapterId = mine?['chapter_id'] as String?;

    // "Members" means the people in your own chapter.
    var membersQuery = _client.from('profiles').select();
    if (chapterId != null) membersQuery = membersQuery.eq('chapter_id', chapterId);
    final membersCount = await membersQuery.count(CountOption.exact);

    final upcomingEventsCount =
        await _client.from('events').select().eq('status', 'upcoming').count(CountOption.exact);

    final openOpportunitiesCount =
        await _client.from('opportunities').select().eq('status', 'open').count(CountOption.exact);

    final profile = mine;

    return CommunityStats(
      totalMembers: membersCount.count,
      upcomingEventsCount: upcomingEventsCount.count,
      openOpportunitiesCount: openOpportunitiesCount.count,
      userPoints: (profile?['points'] as num?)?.toInt() ?? 0,
    );
  }
}
