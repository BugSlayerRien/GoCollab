import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/github_stats.dart';

/// Live GitHub REST client for public user profiles.
///
/// Endpoint: `GET https://api.github.com/users/{username}`
/// Auth: none (public fields only; no API key).
class GithubDataSource {
  GithubDataSource(this._client, {http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$');

  Future<GithubStats> fetchAndCache({required String userId, required String username}) async {
    final handle = _normalizeUsername(username);
    if (handle.isEmpty) {
      throw Exception('Enter a GitHub username first.');
    }
    if (!_usernamePattern.hasMatch(handle)) {
      throw Exception('"$handle" is not a valid GitHub username.');
    }

    late final http.Response response;
    try {
      response = await _http
          .get(
            Uri.https('api.github.com', '/users/$handle'),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'GoCollab',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('GitHub took too long to respond. Please try again.');
    } on http.ClientException {
      throw Exception('Could not reach GitHub. Please try again later.');
    } catch (e) {
      if (e is Exception && e.toString().contains('GitHub')) rethrow;
      throw Exception('No internet connection. Check your network and try again.');
    }

    if (response.statusCode == 404) {
      throw Exception('GitHub user "$handle" was not found.');
    }
    if (response.statusCode == 403) {
      throw Exception('GitHub rate limit reached. Try again in a few minutes.');
    }
    if (response.statusCode != 200) {
      throw Exception('GitHub returned an error (${response.statusCode}). Please try again later.');
    }

    late final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['login'] == null) {
        throw const FormatException('unexpected body');
      }
      json = decoded;
    } on FormatException {
      throw Exception('GitHub returned an invalid response.');
    }

    final stats = GithubStats.fromGithubJson(json);

    await _client.from('github_profiles').upsert({
      'user_id': userId,
      'github_username': stats.username,
      'avatar_url': stats.avatarUrl,
      'bio': stats.bio,
      'public_repos': stats.publicRepos,
      'followers': stats.followers,
      'following': stats.following,
      'profile_url': stats.profileUrl,
      'synced_at': stats.syncedAt!.toIso8601String(),
    }, onConflict: 'user_id');

    return stats;
  }

  Future<GithubStats?> getCached(String userId) async {
    final row = await _client.from('github_profiles').select().eq('user_id', userId).maybeSingle();
    if (row == null) return null;
    return GithubStats.fromCache(row);
  }

  String _normalizeUsername(String raw) {
    var value = raw.trim();
    if (value.startsWith('@')) value = value.substring(1);
    if (value.contains('github.com/')) {
      value = value.split('github.com/').last.split('/').first;
    }
    return value;
  }
}
