import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/analytics_snapshot.dart';

/// All aggregation here happens client-side in Dart after fetching raw rows.
/// This keeps the SQL layer simple (no custom RPC/views required) which is
/// appropriate at GDGoC chapter scale (hundreds, not millions, of rows) —
/// if usage grows, these queries are natural candidates to move into
/// Postgres views or RPC functions without changing the repository
/// contract.
class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<AnalyticsSnapshot> getSnapshot() async {
    final profiles = await _client.from('profiles').select('id, created_at, is_active');
    final events = await _client.from('events').select('id, title, start_at').order('start_at');
    final registrations = await _client.from('event_registrations').select('event_id, status');
    final attendance = await _client.from('attendance').select('event_id, user_id');
    final engagementCount = await _client.from('engagement_logs').select().count(CountOption.exact);

    final profileRows = profiles as List;
    final totalMembers = profileRows.length;
    final activeMembers = profileRows.where((p) => p['is_active'] == true).length;

    // ---- Growth: members joined per month (last 6 months) ----
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final growth = months.map((month) {
      final count = profileRows.where((p) {
        final createdAt = DateTime.parse(p['created_at'] as String);
        return createdAt.year == month.year && createdAt.month == month.month;
      }).length;
      return GrowthPoint(month: month, newMembers: count);
    }).toList();

    // ---- Event performance: registered vs attended per event ----
    final registrationsByEvent = <String, int>{};
    for (final r in registrations as List) {
      if (r['status'] == 'cancelled') continue;
      final eventId = r['event_id'] as String;
      registrationsByEvent[eventId] = (registrationsByEvent[eventId] ?? 0) + 1;
    }
    final attendanceByEvent = <String, int>{};
    for (final a in attendance as List) {
      final eventId = a['event_id'] as String;
      attendanceByEvent[eventId] = (attendanceByEvent[eventId] ?? 0) + 1;
    }

    final eventRows = events as List;
    final performance = eventRows.take(6).map((e) {
      final id = e['id'] as String;
      return EventPerformance(
        eventTitle: e['title'] as String,
        registered: registrationsByEvent[id] ?? 0,
        attended: attendanceByEvent[id] ?? 0,
      );
    }).toList();

    final totalRegistered = registrationsByEvent.values.fold<int>(0, (a, b) => a + b);
    final totalAttended = attendanceByEvent.values.fold<int>(0, (a, b) => a + b);
    final avgAttendanceRate = totalRegistered == 0 ? 0.0 : totalAttended / totalRegistered;

    return AnalyticsSnapshot(
      activeMembers: activeMembers,
      totalMembers: totalMembers,
      totalEvents: eventRows.length,
      averageAttendanceRate: avgAttendanceRate,
      totalEngagementActions: engagementCount.count,
      growth: growth,
      eventPerformance: performance,
    );
  }
}
