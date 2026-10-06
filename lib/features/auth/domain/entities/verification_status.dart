/// Whether an account has been confirmed to belong to a real student /
/// GDGoC member.
///
/// [pending] never appears on `profiles.verification_status` — the database
/// only ever stores unverified/verified/rejected there so that every write
/// stays in the hands of the auto-verify trigger or an officer. Pending is
/// derived in the app from an open row in `verification_requests`.
enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  static VerificationStatus fromKey(String? key) {
    return switch (key) {
      'verified' => VerificationStatus.verified,
      'rejected' => VerificationStatus.rejected,
      'pending' => VerificationStatus.pending,
      _ => VerificationStatus.unverified,
    };
  }

  String get label => switch (this) {
        VerificationStatus.unverified => 'Not verified',
        VerificationStatus.pending => 'Verification pending',
        VerificationStatus.verified => 'Verified member',
        VerificationStatus.rejected => 'Verification rejected',
      };

  bool get isVerified => this == VerificationStatus.verified;
}
