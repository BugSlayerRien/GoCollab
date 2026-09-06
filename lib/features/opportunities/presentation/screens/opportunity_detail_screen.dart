import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/creator_attribution.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';
import '../widgets/create_opportunity_sheet.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity'),
        actions: [
          if (isOfficer)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () {
                final opportunity = opportunityAsync.valueOrNull;
                if (opportunity == null || currentUser == null) return;
                showOpportunityEditorSheet(context, postedBy: currentUser.id, existing: opportunity);
              },
            ),
          if (isOfficer)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _deleteOpportunity(context, ref),
            ),
        ],
      ),
      body: opportunityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: 'Could not load this opportunity.',
          onRetry: () => ref.invalidate(opportunityDetailProvider(opportunityId)),
        ),
        data: (opportunity) => _DetailBody(opportunity: opportunity, isOfficer: isOfficer),
      ),
    );
  }

  Future<void> _deleteOpportunity(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete opportunity?',
      message: 'This permanently removes the posting from Career Hub for all members.',
    );
    if (!confirmed) return;
    final error = await ref.read(createOpportunityControllerProvider.notifier).delete(opportunityId);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Opportunity deleted.',
      errorMessage: error,
    );
    if (error == null) context.pop();
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.opportunity, required this.isOfficer});

  final Opportunity opportunity;
  final bool isOfficer;

  Future<void> _markApplied(BuildContext context, WidgetRef ref) async {
    final note = await _showMarkAppliedDialog(context);
    if (note == null || !context.mounted) return;
    final error = await ref
        .read(applyOpportunityControllerProvider.notifier)
        .markApplied(opportunity, note: note.isEmpty ? null : note);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Marked as applied. You can find this under Career Hub → Applied.',
      errorMessage: error,
    );
  }

  Future<String?> _showMarkAppliedDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as applied?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GoCollab can't verify actions taken on an external site, so this is a self-report. "
              'Officers can see who applied to follow up with the partner if needed.',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Confirmation note (optional)',
                hintText: 'e.g. confirmation email subject, reference number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(savedOpportunityControllerProvider);
    final isApplying = ref.watch(applyOpportunityControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.success(opportunity.type.label),
              const SizedBox(width: AppSpacing.xs),
              if (!opportunity.isOpen) StatusBadge.alert('Closed'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(opportunity.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            opportunity.organization,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.appTextSecondary),
          ),
          if (opportunity.creator != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CreatorAttribution(label: 'Posted by', creator: opportunity.creator),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(
                icon: opportunity.isRemote ? Icons.public_rounded : Icons.location_on_outlined,
                label: opportunity.isRemote ? 'Remote' : (opportunity.location ?? 'Location TBA'),
              ),
              if (opportunity.deadline != null)
                _MetaChip(
                  icon: Icons.event_busy_outlined,
                  label: 'Deadline: ${DateFormatter.date(opportunity.deadline!)}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(opportunity.description, style: Theme.of(context).textTheme.bodyMedium),
          if (opportunity.requirements != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Requirements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(opportunity.requirements!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Apply now',
                  icon: Icons.open_in_new_rounded,
                  onPressed: opportunity.applicationUrl == null
                      ? null
                      : () => launchUrl(Uri.parse(opportunity.applicationUrl!), mode: LaunchMode.externalApplication),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                isSelected: opportunity.isSaved,
                tooltip: opportunity.isSaved ? 'Remove bookmark' : 'Save',
                icon: Icon(opportunity.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                onPressed: isSaving
                    ? null
                    : () async {
                        final error =
                            await ref.read(savedOpportunityControllerProvider.notifier).toggle(opportunity);
                        if (!context.mounted) return;
                        showActionFeedback(
                          context,
                          success: error == null,
                          successMessage: opportunity.isSaved ? 'Removed from saved.' : 'Saved.',
                          errorMessage: error,
                        );
                      },
              ),
            ],
          ),
          if (opportunity.applicationUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (opportunity.hasApplied)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: context.appTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'You marked this as applied'
                      '${opportunity.appliedAt != null ? ' on ${DateFormatter.date(opportunity.appliedAt!)}' : ''}.'
                      ' Find it anytime under Career Hub → Applied.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isApplying ? null : () => _markApplied(context, ref),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Mark as applied'),
                ),
              ),
          ],
          if (isOfficer) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Applicants (self-reported) · ${opportunity.applicants.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'GoCollab cannot verify actions on the external site — use this list to follow up with '
              'the partner organization if you need to confirm an application.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (opportunity.applicants.isEmpty)
              Text('No one has marked this as applied yet.', style: Theme.of(context).textTheme.bodySmall)
            else
              ...opportunity.applicants.map(
                (a) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: a.applicant?.avatarUrl != null ? NetworkImage(a.applicant!.avatarUrl!) : null,
                    child: a.applicant?.avatarUrl == null ? const Icon(Icons.person_outline_rounded) : null,
                  ),
                  title: Text(a.applicant?.name ?? 'Member'),
                  subtitle: Text(
                    [
                      'Applied ${DateFormatter.date(a.appliedAt)}',
                      if (a.note != null && a.note!.trim().isNotEmpty) a.note!.trim(),
                    ].join(' · '),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appTextSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
