import 'package:equatable/equatable.dart';

/// Public GitHub profile snapshot from `GET https://api.github.com/users/{username}`.
class GithubStats extends Equatable {
  const GithubStats({
    required this.username,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.profileUrl,
    this.syncedAt,
  });

  final String username;
  final String? displayName;
  final int publicRepos;
  final int followers;
  final int following;
  final String? avatarUrl;
  final String? bio;
  final String? profileUrl;
  final DateTime? syncedAt;

  /// Maps the GitHub REST JSON body (`login`, `name`, `avatar_url`, …).
  factory GithubStats.fromGithubJson(Map<String, dynamic> json) {
    return GithubStats(
      username: json['login'] as String? ?? '',
      displayName: json['name'] as String?,
      publicRepos: (json['public_repos'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      profileUrl: json['html_url'] as String?,
      syncedAt: DateTime.now(),
    );
  }

  /// Maps a cached `github_profiles` row from Supabase.
  factory GithubStats.fromCache(Map<String, dynamic> row) {
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

  @override
  List<Object?> get props =>
      [username, displayName, publicRepos, followers, following, avatarUrl, bio, profileUrl, syncedAt];
}
