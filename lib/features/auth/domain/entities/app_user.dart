import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// The authenticated identity used throughout the app — a merge of the
/// Supabase `auth.users` session and the corresponding `public.profiles`
/// row. This is the domain-layer representation; the data layer's
/// `AppUserModel` maps raw Supabase JSON into this immutable entity.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.chapterId,
    this.bio,
    this.program,
    this.yearLevel,
    this.contactNumber,
    this.skills = const [],
    this.githubUsername,
    this.linkedinUrl,
    this.points = 0,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? chapterId;
  final String? bio;
  final String? program;
  final String? yearLevel;
  final String? contactNumber;
  final List<String> skills;
  final String? githubUsername;
  final String? linkedinUrl;
  final int points;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? program,
    String? yearLevel,
    String? contactNumber,
    List<String>? skills,
    String? githubUsername,
    String? linkedinUrl,
    UserRole? role,
    int? points,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      chapterId: chapterId,
      bio: bio ?? this.bio,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      contactNumber: contactNumber ?? this.contactNumber,
      skills: skills ?? this.skills,
      githubUsername: githubUsername ?? this.githubUsername,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        avatarUrl,
        chapterId,
        bio,
        program,
        yearLevel,
        contactNumber,
        skills,
        githubUsername,
        linkedinUrl,
        points,
      ];
}
