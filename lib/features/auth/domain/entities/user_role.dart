/// The GoCollab account tiers. Backed by `public.roles` (id 1 = member,
/// id 2 = officer of ONE chapter, id 3 = admin / platform maintainer) — kept
/// as a Dart enum in the domain layer so the rest of the app never has to
/// reason about raw integer role ids.
enum UserRole {
  member(1, 'Member'),
  officer(2, 'Chapter Officer'),
  admin(3, 'Administrator');

  const UserRole(this.id, this.label);

  final int id;
  final String label;

  static UserRole fromId(int id) {
    return UserRole.values.firstWhere(
      (r) => r.id == id,
      orElse: () => UserRole.member,
    );
  }

  bool get isOfficer => this == UserRole.officer;
  bool get isMember => this == UserRole.member;
  bool get isAdmin => this == UserRole.admin;
}
