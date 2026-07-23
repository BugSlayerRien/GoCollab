import 'package:equatable/equatable.dart';

/// A single point on the "member growth" line chart — new members joined
/// during [month].
class GrowthPoint extends Equatable {
  const GrowthPoint({required this.month, required this.newMembers});
  final DateTime month;
  final int newMembers;

  @override
  List<Object?> get props => [month, newMembers];
}

/// Attendance performance for one event, used by the "event performance"
/// bar chart (registered vs. attended).
class EventPerformance extends Equatable {
  const EventPerformance({required this.eventTitle, required this.registered, required this.attended});
  final String eventTitle;
  final int registered;
  final int attended;

  double get attendanceRate => registered == 0 ? 0 : attended / registered;

  @override
  List<Object?> get props => [eventTitle, registered, attended];
}

/// Aggregate figures for the Community Analytics dashboard (module #5).
class AnalyticsSnapshot extends Equatable {
  const AnalyticsSnapshot({
    required this.activeMembers,
    required this.totalMembers,
    required this.totalEvents,
    required this.averageAttendanceRate,
    required this.totalEngagementActions,
    required this.growth,
    required this.eventPerformance,
  });

  final int activeMembers;
  final int totalMembers;
  final int totalEvents;
  final double averageAttendanceRate;
  final int totalEngagementActions;
  final List<GrowthPoint> growth;
  final List<EventPerformance> eventPerformance;

  @override
  List<Object?> get props => [
        activeMembers,
        totalMembers,
        totalEvents,
        averageAttendanceRate,
        totalEngagementActions,
        growth,
        eventPerformance,
      ];
}
