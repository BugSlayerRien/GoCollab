import 'package:shared_preferences/shared_preferences.dart';

/// Last known check-in QR code per event, so a member with no signal at the
/// venue can still show their ticket. Only the opaque QR token and the event
/// title are stored. The server still decides whether a check-in is valid.
class TicketCache {
  const TicketCache._();

  static String _key(String eventId) => 'ticket.$eventId';

  static Future<void> save({required String eventId, required String title, required String qrCode}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(eventId), [title, qrCode]);
    } catch (_) {}
  }

  static Future<void> clear(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(eventId));
    } catch (_) {}
  }

  /// `(title, qrCode)` or null when nothing is cached.
  static Future<(String, String)?> load(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getStringList(_key(eventId));
      if (value == null || value.length != 2) return null;
      return (value[0], value[1]);
    } catch (_) {
      return null;
    }
  }
}
