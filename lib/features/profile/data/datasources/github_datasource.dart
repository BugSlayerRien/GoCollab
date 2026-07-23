import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/github_stats.dart';

/// Fetches public GitHub profile data straight from the GitHub REST API
/// (`GET https://api.github.com/users/{username}`). No authentication is
/// required for this endpoint since it only returns public profile fields —
/// satisfying the "GitHub" profile-linking requirement without needing a
/// GitHub OAuth app. Results are cached in `public.github_profiles` so the
/// profile screen has instant data on subsequent loads and to respect
/// GitHub's unauthenticated rate limit (60 requests/hour per IP).
class GithubDataSource {
  GithubDataSource(this._client);

  final SupabaseClient _client;

  Future<GithubStats> fetchAndCache({required String userId, required String username}) async {
    final response = await http.get(Uri.parse('https://api.github.com/users/$username'));

    if (response.statusCode == 404) {
      throw Exception('GitHub user "$username" was not found.');
    }
    if (response.statusCode != 200) {
      throw Exception('Could not reach GitHub right now. Please try again later.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final stats = GithubStats(
      username: json['login'] as String,
      publicRepos: (json['public_repos'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      profileUrl: json['html_url'] as String?,
      syncedAt: DateTime.now(),
    );

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
    return GithubStats(
      username: row['github_username'] as String,
      publicRepos: (row['public_repos'] as num?)?.toInt() ?? 0,
      followers: (row['followers'] as num?)?.toInt() ?? 0,
      following: (row['following'] as num?)?.toInt() ?? 0,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      profileUrl: row['profile_url'] as String?,
      syncedAt: row['synced_at'] != null ? DateTime.parse(row['synced_at'] as String) : null,
    );
  }
}
