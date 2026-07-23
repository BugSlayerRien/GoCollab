import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/community_stats.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<CommunityStats> getCommunityStats(String userId) async {
    final membersCount = await _client.from('profiles').select().count(CountOption.exact);

    final upcomingEventsCount =
        await _client.from('events').select().eq('status', 'upcoming').count(CountOption.exact);

    final openOpportunitiesCount =
        await _client.from('opportunities').select().eq('status', 'open').count(CountOption.exact);

    final profile = await _client.from('profiles').select('points').eq('id', userId).maybeSingle();

    return CommunityStats(
      totalMembers: membersCount.count,
      upcomingEventsCount: upcomingEventsCount.count,
      openOpportunitiesCount: openOpportunitiesCount.count,
      userPoints: (profile?['points'] as num?)?.toInt() ?? 0,
    );
  }
}
