import 'package:equatable/equatable.dart';

/// An event published by a GDG chapter on gdg.community.dev. The list API
/// only returns the basics; the detail fields stay null until
/// [GdgCommunityApi.fetchDetail] fills them in.
class GdgEvent extends Equatable {
  const GdgEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.url,
    required this.chapterId,
    required this.chapterName,
    this.city,
    this.country,
    this.descriptionHtml,
    this.venueName,
    this.venueAddress,
    this.latitude,
    this.longitude,
    this.isVirtual = false,
    this.capacity,
    this.bannerUrl,
  });

  final int id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String url;
  final int chapterId;
  final String chapterName;
  final String? city;
  final String? country;

  // Detail-only.
  final String? descriptionHtml;
  final String? venueName;
  final String? venueAddress;
  final double? latitude;
  final double? longitude;
  final bool isVirtual;
  final int? capacity;
  final String? bannerUrl;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isUpcoming => endAt.isAfter(DateTime.now());

  @override
  List<Object?> get props => [id, title, startAt, endAt, url, chapterId, descriptionHtml, venueName, latitude, longitude];
}

/// A chapter whose events are shown in the GDG feed (row of `gdg_chapters`).
class GdgChapter extends Equatable {
  const GdgChapter({
    required this.id,
    required this.name,
    this.country = 'PH',
    this.isOwn = false,
    this.ownerChapterId,
  });

  final int id;
  final String name;
  final String country;
  final bool isOwn;

  /// GoCollab chapter that curates this row; only its officers can edit it.
  final String? ownerChapterId;

  @override
  List<Object?> get props => [id, name, country, isOwn, ownerChapterId];
}
