import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/profile/domain/entities/github_stats.dart';

void main() {
  test('GithubStats.fromGithubJson maps REST fields', () {
    final stats = GithubStats.fromGithubJson({
      'login': 'octocat',
      'name': 'The Octocat',
      'avatar_url': 'https://example.com/a.png',
      'bio': 'GitHub mascot',
      'public_repos': 8,
      'followers': 4000,
      'following': 9,
      'html_url': 'https://github.com/octocat',
    });

    expect(stats.username, 'octocat');
    expect(stats.displayName, 'The Octocat');
    expect(stats.publicRepos, 8);
    expect(stats.followers, 4000);
    expect(stats.following, 9);
    expect(stats.profileUrl, 'https://github.com/octocat');
  });
}
