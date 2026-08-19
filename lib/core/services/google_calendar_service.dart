import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Direct REST client for the Google Calendar API v3.
///
/// Uses a standalone [GoogleSignIn] instance scoped to `calendar.events` so
/// the user is prompted for calendar permission independently of the main
/// Supabase auth session. The access token is obtained on-demand and
/// refreshed automatically by the Google Sign-In SDK.
class GoogleCalendarService {
  GoogleCalendarService._();

  static const _calendarScope = 'https://www.googleapis.com/auth/calendar.events';
  static const _baseUrl = 'https://www.googleapis.com/calendar/v3';

  static GoogleSignIn get _googleSignIn => GoogleSignIn(
        clientId: kIsWeb && Env.hasGoogleSignIn ? Env.googleWebClientId : null,
        scopes: const [_calendarScope],
      );

  static const _reauthMessage =
      'Calendar access is missing or expired. Sign out, then sign in again with Google '
      'to grant calendar permission.';

  static bool _signedInWithGoogle(User? user) {
    if (user == null) return false;
    if (user.appMetadata['provider'] == 'google') return true;
    return user.identities?.any((id) => id.provider == 'google') ?? false;
  }

  /// Returns a valid Google access token with calendar scope.
  ///
  /// Reuses the Supabase Google OAuth [Session.providerToken] so there is no
  /// second Google popup (which would use a random dev-server port and fail).
  static Future<String?> _getAccessToken() async {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    final user = session?.user;
    final googleUser = _signedInWithGoogle(user);

    final providerToken = session?.providerToken;
    if (providerToken != null && providerToken.isNotEmpty) {
      return providerToken;
    }

    if (googleUser) {
      throw const CalendarAuthException(_reauthMessage);
    }

    if (!Env.hasGoogleSignIn) return null;

    try {
      final googleSignIn = _googleSignIn;
      var account = googleSignIn.currentUser;
      account ??= await googleSignIn.signInSilently();
      account ??= await googleSignIn.signIn();
      if (account == null) return null;

      final googleAuth = await account.authentication;
      if (googleAuth.accessToken == null) {
        await googleSignIn.signOut();
        return null;
      }
      return googleAuth.accessToken;
    } catch (e) {
      debugPrint('[GoogleCalendar] Auth error: $e');
      final msg = e.toString();
      if (msg.contains('origin_mismatch')) {
        throw const CalendarAuthException(
          'Google OAuth origin mismatch. Sign in with Google from the login screen '
          'instead of using a separate calendar sign-in.',
        );
      }
      if (msg.contains('access_denied') || msg.contains('403')) {
        throw const CalendarAuthException(
          'Calendar access was denied. Add your email as a Test user in Google Cloud '
          'Console and enable the Google Calendar API.',
        );
      }
      return null;
    }
  }

  static Future<String?> _getAccessTokenAfter401() async {
    final auth = Supabase.instance.client.auth;
    if (_signedInWithGoogle(auth.currentUser)) {
      try {
        await auth.refreshSession();
        final token = auth.currentSession?.providerToken;
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        debugPrint('[GoogleCalendar] refreshSession failed: $e');
      }
      throw const CalendarAuthException(_reauthMessage);
    }
    await _googleSignIn.signOut();
    return _getAccessToken();
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// GET — Retrieves a single calendar event by its Google Calendar event ID.
  static Future<Map<String, dynamic>?> getEvent(String calendarEventId) async {
    final token = await _getAccessToken();
    if (token == null) throw const CalendarAuthException();

    final url = '$_baseUrl/calendars/primary/events/$calendarEventId';
    final response = await http.get(Uri.parse(url), headers: _headers(token));

    if (response.statusCode == 404) return null;
    if (response.statusCode == 401) {
      final retryToken = await _getAccessTokenAfter401();
      if (retryToken == null) throw const CalendarAuthException(_reauthMessage);
      final retry = await http.get(Uri.parse(url), headers: _headers(retryToken));
      if (retry.statusCode == 401) throw const CalendarAuthException(_reauthMessage);
      if (retry.statusCode == 404) return null;
      if (retry.statusCode != 200) {
        throw CalendarApiException('Failed to get event (${retry.statusCode})', retry.body);
      }
      return json.decode(retry.body) as Map<String, dynamic>;
    }
    if (response.statusCode != 200) {
      throw CalendarApiException('Failed to get event (${response.statusCode})', response.body);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// GET — Lists upcoming calendar events from the user's primary calendar.
  static Future<List<Map<String, dynamic>>> listUpcomingEvents({int maxResults = 10}) async {
    final token = await _getAccessToken();
    if (token == null) throw const CalendarAuthException();

    final now = DateTime.now().toUtc().toIso8601String();
    final url = '$_baseUrl/calendars/primary/events'
        '?maxResults=$maxResults&orderBy=startTime&singleEvents=true&timeMin=$now';
    final response = await http.get(Uri.parse(url), headers: _headers(token));

    if (response.statusCode == 401) {
      throw const CalendarAuthException(_reauthMessage);
    }
    if (response.statusCode != 200) {
      throw CalendarApiException('Failed to list events (${response.statusCode})', response.body);
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    return (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// POST — Creates a new event on the user's primary Google Calendar.
  /// Returns the created event's ID.
  static Future<String> createEvent({
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    final token = await _getAccessToken();
    if (token == null) throw const CalendarAuthException();

    final body = json.encode({
      'summary': summary,
      'description': description,
      'location': location ?? '',
      'start': {'dateTime': startTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      'end': {'dateTime': endTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      'reminders': {
        'useDefault': false,
        'overrides': [
          {'method': 'popup', 'minutes': 30},
        ],
      },
    });

    final url = '$_baseUrl/calendars/primary/events';
    final response = await http.post(Uri.parse(url), headers: _headers(token), body: body);

    if (response.statusCode == 401) {
      final retryToken = await _getAccessTokenAfter401();
      if (retryToken == null) throw const CalendarAuthException(_reauthMessage);
      final retry = await http.post(Uri.parse(url), headers: _headers(retryToken), body: body);
      if (retry.statusCode == 401) throw const CalendarAuthException(_reauthMessage);
      if (retry.statusCode != 200) {
        throw CalendarApiException('Failed to create event (${retry.statusCode})', retry.body);
      }
      final data = json.decode(retry.body) as Map<String, dynamic>;
      return data['id'] as String;
    }
    if (response.statusCode != 200) {
      throw CalendarApiException('Failed to create event (${response.statusCode})', response.body);
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// PATCH — Updates an existing event on the user's primary Google Calendar.
  static Future<void> updateEvent({
    required String calendarEventId,
    required String summary,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    final token = await _getAccessToken();
    if (token == null) throw const CalendarAuthException();

    final body = json.encode({
      'summary': summary,
      'description': description,
      'location': location ?? '',
      'start': {'dateTime': startTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      'end': {'dateTime': endTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
    });

    final url = '$_baseUrl/calendars/primary/events/$calendarEventId';
    final response = await http.patch(Uri.parse(url), headers: _headers(token), body: body);

    if (response.statusCode == 401) {
      final retryToken = await _getAccessTokenAfter401();
      if (retryToken == null) throw const CalendarAuthException(_reauthMessage);
      final retry = await http.patch(Uri.parse(url), headers: _headers(retryToken), body: body);
      if (retry.statusCode == 401) throw const CalendarAuthException(_reauthMessage);
      if (retry.statusCode != 200) {
        throw CalendarApiException('Failed to update event (${retry.statusCode})', retry.body);
      }
      return;
    }
    if (response.statusCode != 200) {
      throw CalendarApiException('Failed to update event (${response.statusCode})', response.body);
    }
  }

  /// DELETE — Removes an event from the user's primary Google Calendar.
  static Future<void> deleteEvent(String calendarEventId) async {
    final token = await _getAccessToken();
    if (token == null) throw const CalendarAuthException();

    final url = '$_baseUrl/calendars/primary/events/$calendarEventId';
    final response = await http.delete(Uri.parse(url), headers: _headers(token));

    if (response.statusCode == 401) {
      final retryToken = await _getAccessTokenAfter401();
      if (retryToken == null) throw const CalendarAuthException(_reauthMessage);
      final retry = await http.delete(Uri.parse(url), headers: _headers(retryToken));
      if (retry.statusCode == 401) throw const CalendarAuthException(_reauthMessage);
      if (retry.statusCode != 204 && retry.statusCode != 200 && retry.statusCode != 410) {
        throw CalendarApiException('Failed to delete event (${retry.statusCode})', retry.body);
      }
      return;
    }
    if (response.statusCode != 204 && response.statusCode != 200 && response.statusCode != 410) {
      throw CalendarApiException('Failed to delete event (${response.statusCode})', response.body);
    }
  }

  /// Sign out of Google Calendar (does not affect Supabase session).
  static Future<void> disconnect() async {
    await _googleSignIn.signOut();
  }

  /// Whether the user has previously granted calendar access.
  static bool get isSignedIn => _googleSignIn.currentUser != null;
}

class CalendarAuthException implements Exception {
  const CalendarAuthException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Calendar access was denied or expired. Please try again.';
}

class CalendarApiException implements Exception {
  const CalendarApiException(this.message, [this.responseBody]);
  final String message;
  final String? responseBody;

  @override
  String toString() => message;
}
