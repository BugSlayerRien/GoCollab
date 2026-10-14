import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/application_claim.dart';
import '../providers/claim_providers.dart';

/// Officer-only queue of "I applied externally" proofs awaiting approval.
/// Approving is what releases the points.
class ApplicationClaimsScreen extends ConsumerWidget {
  const ApplicationClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimsAsync = ref.watch(pendingClaimsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Application claims')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingClaimsProvider),
        child: claimsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ErrorStateView(
            message: 'Could not load claims.',
            onRetry: () => ref.invalidate(pendingClaimsProvider),
          ),
          data: (claims) {
            if (claims.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.redeem_rounded,
                  title: 'Nothing to review',
                  message: 'Proofs of external applications appear here when members claim their points.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: claims.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _ClaimCard(claim: claims[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ClaimCard extends ConsumerWidget {
  const _ClaimCard({required this.claim});
  final ApplicationClaim claim;

  Future<void> _decide(BuildContext context, WidgetRef ref, {required bool approve}) async {
    String? reason;
    if (!approve) {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reject proof?'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Reason', hintText: 'e.g. Screenshot is unreadable'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.googleRed),
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null) return;
    }
    if (!context.mounted) return;
    final error = await ref.read(claimActionsControllerProvider.notifier).review(
          claim.id,
          approve: approve,
          reason: reason,
        );
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: approve ? 'Approved. 10 points awarded.' : 'Claim rejected.',
      errorMessage: error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorking = ref.watch(claimActionsControllerProvider);
    final proofAsync = claim.proofPath == null ? null : ref.watch(claimProofUrlProvider(claim.proofPath!));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(claim.opportunityTitle ?? 'Opportunity', style: Theme.of(context).textTheme.titleSmall),
          Text(
            '${claim.applicantName ?? 'Member'} · tapped Apply ${DateFormatter.dateTime(claim.clickedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (proofAsync != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: proofAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Could not load proof.')),
                  data: (url) => InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(AppSpacing.md),
                        child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)),
                      ),
                    ),
                    child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.outlined,
                  color: AppColors.googleRed,
                  isLoading: isWorking,
                  onPressed: () => _decide(context, ref, approve: false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve',
                  isLoading: isWorking,
                  onPressed: () => _decide(context, ref, approve: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
