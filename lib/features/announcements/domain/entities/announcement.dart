import 'package:equatable/equatable.dart';

enum AnnouncementCategory {
  general,
  event,
  career,
  partnership,
  urgent;

  static AnnouncementCategory fromKey(String key) {
    return AnnouncementCategory.values.firstWhere((c) => c.name == key, orElse: () => AnnouncementCategory.general);
  }

  String get label => switch (this) {
        AnnouncementCategory.general => 'General',
        AnnouncementCategory.event => 'Event',
        AnnouncementCategory.career => 'Career',
        AnnouncementCategory.partnership => 'Partnership',
        AnnouncementCategory.urgent => 'Urgent',
      };
}

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
    this.isPinned = false,
    this.authorName,
  });

  final String id;
  final String title;
  final String body;
  final AnnouncementCategory category;
  final DateTime publishedAt;
  final String? imageUrl;
  final bool isPinned;
  final String? authorName;

  @override
  List<Object?> get props => [id, title, body, category, publishedAt, imageUrl, isPinned, authorName];
}
