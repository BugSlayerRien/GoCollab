import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Firebase Cloud Messaging bootstrap for push notifications — announcements,
/// event reminders, registration confirmations, career opportunities, and
/// partnership updates (per spec's FCM requirement).
///
/// This project ships without a real Firebase project wired in (no
/// `firebase_options.dart` credentials were provided), so [initialize] is
/// **defensive**: any failure during `Firebase.initializeApp()` or FCM setup
/// is caught and logged rather than crashing the app, so GoCollab remains
/// fully usable (Supabase Auth/DB features unaffected) in environments
/// without Firebase configured. To go live:
///   1. Run `flutterfire configure` to generate `firebase_options.dart`.
///   2. Add `google-services.json` (Android) / `GoogleService-Info.plist`
///      (iOS) to the native projects.
///   3. Call [NotificationService.initialize] in `main.dart` (already wired).
///   4. Forward FCM device tokens to a `device_tokens` table / Supabase Edge
///      Function so your backend can target sends via the FCM HTTP v1 API.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('[NotificationService] Firebase not configured, push notifications disabled: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
  }

  static Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'gocollab_general',
      'GoCollab Notifications',
      channelDescription: 'Announcements, event reminders, and career opportunities',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
