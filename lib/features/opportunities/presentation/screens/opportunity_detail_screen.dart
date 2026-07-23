import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Opportunity')),
      body: opportunityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorStateView(
          message: 'Could not load this opportunity.',
          onRetry: () => ref.invalidate(opportunityDetailProvider(opportunityId)),
        ),
        data: (opportunity) => _DetailBody(opportunity: opportunity),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(savedOpportunityControllerProvider);

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
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
                icon: Icon(opportunity.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                onPressed: isSaving ? null : () => ref.read(savedOpportunityControllerProvider.notifier).toggle(opportunity),
              ),
            ],
          ),
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
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
