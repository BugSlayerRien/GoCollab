import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/application_claim.dart';
import '../providers/claim_providers.dart';

/// Lets a member redeem points for applying on an external site: tap Apply,
/// upload a screenshot of the confirmation, an officer approves it.
class ApplicationClaimCard extends ConsumerWidget {
  const ApplicationClaimCard({super.key, required this.opportunityId});

  final String opportunityId;

  Future<void> _pickAndSubmit(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !context.mounted) return;
    final error = await ref.read(claimActionsControllerProvider.notifier).submitProof(opportunityId, file);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Proof submitted. An officer will review it.',
      errorMessage: error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null || user.role == UserRole.officer) return const SizedBox.shrink();

    final claim = ref.watch(myClaimProvider(opportunityId)).valueOrNull;
    final isWorking = ref.watch(claimActionsControllerProvider);

    final (IconData icon, Color color, String title, String body) = switch (claim) {
      null => (
          Icons.redeem_rounded,
          AppColors.googleBlue,
          'Earn 10 points for applying',
          'Tap "Apply now", finish your application on the partner site, then come back and upload your confirmation.',
        ),
      ApplicationClaim(isApproved: true) => (
          Icons.check_circle_rounded,
          AppColors.googleGreen,
          'Points earned',
          'An officer confirmed your application and 10 points were added.',
        ),
      ApplicationClaim(isPending: true) => (
          Icons.hourglass_top_rounded,
          AppColors.googleYellow,
          'Proof under review',
          'An officer is checking your confirmation.',
        ),
      ApplicationClaim(isRejected: true) => (
          Icons.error_outline_rounded,
          AppColors.googleRed,
          'Proof not accepted',
          claim.rejectionReason?.trim().isNotEmpty == true
              ? 'Officer note: ${claim.rejectionReason}. You can upload a clearer screenshot.'
              : 'You can upload a clearer screenshot.',
        ),
      _ => (
          Icons.upload_file_rounded,
          AppColors.googleBlue,
          'Did you finish applying?',
          'Upload a screenshot of the confirmation page or email to claim 10 points.',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary)),
          if (claim != null && claim.canSubmitProof) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: claim.isRejected ? 'Upload new proof' : 'Upload proof',
              icon: Icons.upload_rounded,
              isLoading: isWorking,
              onPressed: () => _pickAndSubmit(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
