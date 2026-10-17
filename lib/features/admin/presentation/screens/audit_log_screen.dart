import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/admin_providers.dart';

const _labels = {
  'verification.approved': 'Verification approved',
  'verification.rejected': 'Verification rejected',
  'claim.approved': 'Claim approved',
  'claim.rejected': 'Claim rejected',
  'claim.bulk_approved': 'Claims approved (bulk)',
  'claim.bulk_rejected': 'Claims rejected (bulk)',
  'role.promote': 'Officer appointed',
  'role.demote': 'Officer role removed',
  'member.chapter_assigned': 'Member moved to chapter',
  'chapter.created': 'Chapter created',
  'chapter.updated': 'Chapter updated',
  'chapter.deleted': 'Chapter deleted',
  'domain.added': 'School domain added',
  'domain.removed': 'School domain removed',
  'certificates.issued': 'Certificates issued',
  'attendance.undone': 'Check-in undone',
  'attendance.no_shows_marked': 'No-shows marked',
};

/// Read-only history. An officer sees their chapter's entries; an admin sees
/// everything (the filtering is enforced by RLS, not by this screen).
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  String _summary(AuditEntry e) {
    final parts = <String>[];
    final count = e.detail['count'];
    if (count != null) parts.add('$count item(s)');
    final reason = e.detail['reason'];
    if (reason is String && reason.isNotEmpty) parts.add('Reason: $reason');
    if (e.detail['points_reversed'] == true) parts.add('points reversed');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(auditLogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(auditLogProvider),
        child: log.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ErrorStateView(
            message: 'Could not load the audit log.',
            onRetry: () => ref.invalidate(auditLogProvider),
          ),
          data: (entries) => entries.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyState(icon: Icons.history_rounded, title: 'Nothing recorded yet', message: 'Decisions will appear here.'),
                ])
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final summary = _summary(e);
                    return ListTile(
                      title: Text(_labels[e.action] ?? e.action),
                      subtitle: Text(
                        '${e.actorName ?? 'System'} · ${DateFormatter.dateTime(e.createdAt)}'
                        '${summary.isEmpty ? '' : '\n$summary'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                      ),
                      isThreeLine: summary.isNotEmpty,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
