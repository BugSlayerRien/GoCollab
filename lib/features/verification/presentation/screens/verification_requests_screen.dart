import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/services/id_ocr_service.dart';
import '../../domain/entities/verification_request.dart';
import '../providers/verification_providers.dart';

/// Officer-only queue of members who could not be auto-verified by school
/// email and submitted a school ID instead.
class VerificationRequestsScreen extends ConsumerWidget {
  const VerificationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingVerificationRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification requests')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pendingVerificationRequestsProvider),
        child: requestsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 160),
          ),
          error: (error, _) => ErrorStateView(
            message: 'Could not load verification requests.',
            onRetry: () => ref.invalidate(pendingVerificationRequestsProvider),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'Nothing to review',
                    message:
                        'Members who sign up with a school email are verified automatically. '
                        'Anyone who needs a manual check will appear here.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _RequestCard(request: requests[index]),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final VerificationRequest request;

  Future<void> _decide(BuildContext context, WidgetRef ref, {required bool approve}) async {
    String? reason;

    if (!approve) {
      reason = await _askRejectionReason(context);
      if (reason == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Approve this member?'),
          content: Text(
            'This confirms ${request.applicant?.name ?? 'this member'} is a real student member. '
            'They will be able to register for events and earn community points.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!context.mounted) return;
    final error = await ref.read(verificationActionsControllerProvider.notifier).review(
          requestId: request.id,
          approve: approve,
          reason: reason,
        );
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: approve ? 'Member verified.' : 'Request rejected.',
      errorMessage: error,
    );
  }

  Future<String?> _askRejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The member sees this note and can submit again.'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. ID photo is unreadable',
              ),
            ),
          ],
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
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWorking = ref.watch(verificationActionsControllerProvider);
    final docUrlAsync = ref.watch(verificationDocumentUrlProvider(request.idDocumentPath));

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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: request.applicant?.avatarUrl != null
                    ? CachedNetworkImageProvider(request.applicant!.avatarUrl!)
                    : null,
                child: request.applicant?.avatarUrl == null
                    ? const Icon(Icons.person_outline_rounded, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.applicant?.name ?? 'Member',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Student no. ${request.studentNumber} · ${DateFormatter.date(request.submittedAt)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.appTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Builder(builder: (_) {
            final ocr = OcrResult.fromKey(request.ocrResult);
            return switch (ocr) {
              OcrResult.matched => StatusBadge.success(ocr.label),
              OcrResult.partial => StatusBadge.pending(ocr.label),
              OcrResult.mismatch => StatusBadge.alert(ocr.label),
              OcrResult.notRun => StatusBadge.info(ocr.label),
            };
          }),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: docUrlAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Could not load ID photo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                data: (url) => InkWell(
                  onTap: () => _showFullImage(context, url),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
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

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
