import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/widgets/event_map_preview.dart';
import '../../domain/entities/communication_log.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/partner.dart';
import '../../domain/entities/sponsorship.dart';
import '../providers/partnership_providers.dart';
import '../widgets/log_communication_sheet.dart';
import '../widgets/schedule_meeting_sheet.dart';

class PartnerDetailScreen extends ConsumerWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(partnerDetailProvider(partnerId));

    return partnerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: ErrorStateView(message: 'Could not load partner.', onRetry: () => ref.invalidate(partnerDetailProvider(partnerId))),
      ),
      data: (partner) => _PartnerDetailView(partner: partner),
    );
  }
}

class _PartnerDetailView extends ConsumerWidget {
  const _PartnerDetailView({required this.partner});
  final Partner partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(partner.name),
          bottom: const TabBar(
            tabs: [Tab(text: 'Overview'), Tab(text: 'Sponsorships'), Tab(text: 'Meetings & Logs')],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(partner: partner),
            _SponsorshipsTab(partnerId: partner.id),
            _MeetingsAndLogsTab(partnerId: partner.id),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.partner});
  final Partner partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            StatusBadge.info(partner.category.label),
            PopupMenuButton<CollaborationStatus>(
              onSelected: (status) => ref.read(partnershipActionsControllerProvider.notifier).updateStatus(partner.id, status),
              itemBuilder: (context) => CollaborationStatus.values
                  .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              child: StatusBadge(
                label: partner.collaborationStatus.label,
                color: partner.collaborationStatus == CollaborationStatus.active
                    ? AppColors.googleGreen
                    : partner.collaborationStatus == CollaborationStatus.ended
                        ? AppColors.googleRed
                        : AppColors.googleYellow,
                icon: Icons.edit_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (partner.description != null) ...[
          Text(partner.description!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (partner.contactPerson != null) _InfoTile(icon: Icons.person_outline_rounded, label: partner.contactPerson!),
        if (partner.contactEmail != null) _InfoTile(icon: Icons.mail_outline_rounded, label: partner.contactEmail!),
        if (partner.contactPhone != null) _InfoTile(icon: Icons.phone_outlined, label: partner.contactPhone!),
        if (partner.address != null) _InfoTile(icon: Icons.place_outlined, label: partner.address!),
        if (partner.website != null)
          _InfoTile(
            icon: Icons.public_rounded,
            label: partner.website!,
            onTap: () => launchUrl(Uri.parse(partner.website!), mode: LaunchMode.externalApplication),
          ),
        if (partner.hasLocation) ...[
          const SizedBox(height: AppSpacing.lg),
          LocationMapPreview(latitude: partner.latitude!, longitude: partner.longitude!, label: partner.name),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
    );
  }
}

class _SponsorshipsTab extends ConsumerWidget {
  const _SponsorshipsTab({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsorshipsAsync = ref.watch(sponsorshipsProvider(partnerId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSponsorshipDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: sponsorshipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load sponsorships.')),
        data: (sponsorships) {
          if (sponsorships.isEmpty) {
            return const EmptyState(
              icon: Icons.volunteer_activism_outlined,
              title: 'No sponsorships yet',
              message: 'Track monetary, in-kind, or media sponsorships from this partner.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sponsorships.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final s = sponsorships[index];
              return ListTile(
                tileColor: AppColors.surfaceLightGray,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                title: Text(s.title),
                subtitle: Text('${s.sponsorshipType} • ${s.status}${s.amount != null ? ' • ${s.currency} ${s.amount!.toStringAsFixed(0)}' : ''}'),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSponsorshipDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String type = 'monetary';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New sponsorship'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const ['monetary', 'in-kind', 'media', 'venue', 'other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? 'monetary'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await ref.read(partnershipActionsControllerProvider.notifier).createSponsorship(
                      Sponsorship(
                        id: '',
                        partnerId: partnerId,
                        title: titleController.text.trim(),
                        sponsorshipType: type,
                        status: 'pending',
                      ),
                    );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingsAndLogsTab extends ConsumerWidget {
  const _MeetingsAndLogsTab({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider(partnerId));
    final logsAsync = ref.watch(communicationsProvider(partnerId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'schedule-meeting',
            onPressed: () => showScheduleMeetingSheet(context, partnerId: partnerId),
            child: const Icon(Icons.event_available_rounded),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton(
            heroTag: 'log-comm',
            onPressed: currentUser == null
                ? null
                : () => showLogCommunicationSheet(context, partnerId: partnerId, communicatedBy: currentUser.id),
            child: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Upcoming meetings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          meetingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Could not load meetings.'),
            data: (meetings) => meetings.isEmpty
                ? Text('No meetings scheduled.', style: Theme.of(context).textTheme.bodySmall)
                : Column(children: meetings.map((m) => _MeetingTile(meeting: m)).toList()),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Communication log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Could not load communication logs.'),
            data: (logs) => logs.isEmpty
                ? Text('No communications logged yet.', style: Theme.of(context).textTheme.bodySmall)
                : Column(children: logs.map((l) => _CommunicationTile(log: l)).toList()),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({required this.meeting});
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_rounded, color: AppColors.googleYellow),
      title: Text(meeting.title),
      subtitle: Text('${DateFormatter.dateTime(meeting.scheduledAt)}${meeting.location != null ? ' • ${meeting.location}' : ''}'),
      trailing: StatusBadge.pending(meeting.status),
    );
  }
}

class _CommunicationTile extends StatelessWidget {
  const _CommunicationTile({required this.log});
  final CommunicationLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        log.direction == 'inbound' ? Icons.call_received_rounded : Icons.call_made_rounded,
        color: AppColors.googleBlue,
      ),
      title: Text(log.subject),
      subtitle: Text('${log.contactMethod} • ${DateFormatter.date(log.communicatedAt)}${log.communicatedByName != null ? ' • ${log.communicatedByName}' : ''}'),
    );
  }
}
