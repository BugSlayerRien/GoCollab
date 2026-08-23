/// Profile metadata for content created by an officer/member.
class ContentCreator {
  const ContentCreator({
    this.id,
    this.name,
    this.avatarUrl,
  });

  final String? id;
  final String? name;
  final String? avatarUrl;

  bool get hasDisplay => name != null && name!.trim().isNotEmpty;

  static ContentCreator? fromProfileMap(
    Map<String, dynamic>? profile, {
    String? fallbackId,
  }) {
    if (profile == null && fallbackId == null) return null;
    final name = profile?['full_name'] as String?;
    final avatarUrl = profile?['avatar_url'] as String?;
    if ((name == null || name.trim().isEmpty) && fallbackId == null) return null;
    return ContentCreator(
      id: profile?['id'] as String? ?? fallbackId,
      name: name?.trim(),
      avatarUrl: avatarUrl?.trim().isNotEmpty == true ? avatarUrl : null,
    );
  }
}
