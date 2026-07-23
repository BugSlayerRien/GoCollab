import 'package:equatable/equatable.dart';

/// Public GitHub profile snapshot, synced from the GitHub REST API
/// (`GET /users/{username}` — unauthenticated, no API key required for
/// public read-only profile data) and cached in `public.github_profiles`.
class GithubStats extends Equatable {
  const GithubStats({
    required this.username,
    required this.publicRepos,
    required this.followers,
    required this.following,
    this.avatarUrl,
    this.bio,
    this.profileUrl,
    this.syncedAt,
  });

  final String username;
  final int publicRepos;
  final int followers;
  final int following;
  final String? avatarUrl;
  final String? bio;
  final String? profileUrl;
  final DateTime? syncedAt;

  @override
  List<Object?> get props => [username, publicRepos, followers, following, avatarUrl, bio, profileUrl, syncedAt];
}
