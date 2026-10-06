import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/verification_status.dart';

/// Maps a `public.profiles` row (joined implicitly with `auth.users` via
/// the session) into the domain [AppUser] entity.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.avatarUrl,
    super.chapterId,
    super.bio,
    super.program,
    super.yearLevel,
    super.contactNumber,
    super.skills,
    super.githubUsername,
    super.linkedinUrl,
    super.points,
    super.verificationStatus,
    super.studentNumber,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: (map['full_name'] as String?) ?? 'GoCollab Member',
      role: UserRole.fromId((map['role_id'] as num?)?.toInt() ?? 1),
      avatarUrl: map['avatar_url'] as String?,
      chapterId: map['chapter_id'] as String?,
      bio: map['bio'] as String?,
      program: map['program'] as String?,
      yearLevel: map['year_level'] as String?,
      contactNumber: map['contact_number'] as String?,
      skills: (map['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      githubUsername: map['github_username'] as String?,
      linkedinUrl: map['linkedin_url'] as String?,
      points: (map['points'] as num?)?.toInt() ?? 0,
      verificationStatus: VerificationStatus.fromKey(map['verification_status'] as String?),
      studentNumber: map['student_number'] as String?,
    );
  }

  /// Whitelist of self-editable columns. `verification_status`,
  /// `student_number`, `role_id` and `points` are intentionally absent —
  /// a BEFORE UPDATE trigger on `profiles` rejects them from non-officers.
  Map<String, dynamic> toUpdateMap() {
    return {
      'full_name': fullName,
      'bio': bio,
      'program': program,
      'year_level': yearLevel,
      'contact_number': contactNumber,
      'skills': skills,
      'github_username': githubUsername,
      'linkedin_url': linkedinUrl,
    };
  }
}
