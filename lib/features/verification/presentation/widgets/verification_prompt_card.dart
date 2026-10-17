import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/domain/entities/verification_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/verification_providers.dart';

/// Nudge shown to members who still need to verify. Renders nothing for
/// verified members and for officers, so it can be dropped into any screen
/// unconditionally.
class VerificationPromptCard extends ConsumerWidget {
  const VerificationPromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null || user.role != UserRole.member || user.isVerified) {
      return const SizedBox.shrink();
    }

    final status = ref.watch(effectiveVerificationStatusProvider);
    if (status == VerificationStatus.verified) return const SizedBox.shrink();

    final isPending = status == VerificationStatus.pending;
    final accent = isPending ? AppColors.googleYellow : AppColors.googleBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.shield_outlined,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Verification in review' : 'Verify your account',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  isPending
                      ? 'An officer is checking your submission.'
                      : 'Get verified to register for events and earn community points.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.appTextSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/verify'),
            child: Text(isPending ? 'View' : 'Verify'),
          ),
        ],
      ),
    );
  }
}
