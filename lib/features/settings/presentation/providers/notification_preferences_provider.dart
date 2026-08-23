import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _eventRemindersKey = 'pref_push_event_reminders';
const _announcementsKey = 'pref_push_announcements';
const _opportunityAlertsKey = 'pref_push_opportunity_alerts';

class NotificationPreferences {
  const NotificationPreferences({
    this.eventReminders = true,
    this.communityAnnouncements = true,
    this.opportunityAlerts = true,
  });

  final bool eventReminders;
  final bool communityAnnouncements;
  final bool opportunityAlerts;

  NotificationPreferences copyWith({
    bool? eventReminders,
    bool? communityAnnouncements,
    bool? opportunityAlerts,
  }) {
    return NotificationPreferences(
      eventReminders: eventReminders ?? this.eventReminders,
      communityAnnouncements: communityAnnouncements ?? this.communityAnnouncements,
      opportunityAlerts: opportunityAlerts ?? this.opportunityAlerts,
    );
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesController, NotificationPreferences>((ref) {
  return NotificationPreferencesController();
});

class NotificationPreferencesController extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesController() : super(const NotificationPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      eventReminders: prefs.getBool(_eventRemindersKey) ?? true,
      communityAnnouncements: prefs.getBool(_announcementsKey) ?? true,
      opportunityAlerts: prefs.getBool(_opportunityAlertsKey) ?? true,
    );
  }

  Future<void> setEventReminders(bool value) async {
    state = state.copyWith(eventReminders: value);
    await _save(_eventRemindersKey, value);
  }

  Future<void> setCommunityAnnouncements(bool value) async {
    state = state.copyWith(communityAnnouncements: value);
    await _save(_announcementsKey, value);
  }

  Future<void> setOpportunityAlerts(bool value) async {
    state = state.copyWith(opportunityAlerts: value);
    await _save(_opportunityAlertsKey, value);
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
