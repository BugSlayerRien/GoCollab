import '../../../../core/models/content_creator.dart';
import '../../domain/entities/announcement.dart';

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.category,
    required super.publishedAt,
    super.imageUrl,
    super.isPinned,
    super.creatorName,
    super.creatorAvatarUrl,
    super.createdBy,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    final creator = ContentCreator.fromProfileMap(
      map['creator'] as Map<String, dynamic>?,
      fallbackId: map['created_by'] as String?,
    );
    return AnnouncementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      category: AnnouncementCategory.fromKey(map['category'] as String),
      publishedAt: DateTime.parse(map['published_at'] as String),
      imageUrl: map['image_url'] as String?,
      isPinned: map['is_pinned'] as bool? ?? false,
      creatorName: creator?.name,
      creatorAvatarUrl: creator?.avatarUrl,
      createdBy: creator?.id ?? map['created_by'] as String?,
    );
  }
}
