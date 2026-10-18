import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/in_app_browser.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/attendance_export.dart';
import '../../domain/entities/event_attendee.dart';
import '../providers/event_providers.dart';

/// Officer-only: who registered, who actually showed up, and a manual
/// check-in for members whose QR code can't be scanned.
class EventAttendeesScreen extends ConsumerStatefulWidget {
  const EventAttendeesScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends ConsumerState<EventAttendeesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  String get eventId => widget.eventId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendeesAsync = ref.watch(eventAttendeesProvider(eventId));
    final isWorking = ref.watch(eventActionsControllerProvider);
    final event = ref.watch(eventDetailProvider(eventId)).valueOrNull;
    final eventEnded = event != null && event.endAt.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(eventAttendeesProvider(eventId)),
        child: attendeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ErrorStateView(
            message: 'Could not load attendees.',
            onRetry: () => ref.invalidate(eventAttendeesProvider(eventId)),
          ),
          data: (attendees) {
            if (attendees.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No registrations yet',
                  message: 'Members who register for this event will appear here.',
                ),
              ]);
            }
            final checkedIn = attendees.where((a) => a.isCheckedIn).length;
            final needle = _query.trim().toLowerCase();
            final visible = needle.isEmpty
                ? attendees
                : attendees
                    .where((a) =>
                        a.name.toLowerCase().contains(needle) ||
                        (a.studentNumber?.toLowerCase().contains(needle) ?? false))
                    .toList();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or student number',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      TextButton.icon(
                        onPressed: visible.isEmpty
                            ? null
                            : () async {
                                await Clipboard.setData(ClipboardData(text: buildAttendanceTsv(visible)));
                                if (!context.mounted) return;
                                showActionFeedback(
                                  context,
                                  success: true,
                                  successMessage:
                                      'Copied ${visible.length} row${visible.length == 1 ? '' : 's'}. Paste into Google Sheets.',
                                );
                              },
                        icon: const Icon(Icons.copy_all_rounded, size: 18),
                        label: const Text('Copy for Google Sheets'),
                      ),
                      TextButton.icon(
                        onPressed: () => openExternal(context, 'https://sheets.new'),
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: const Text('Open Sheets'),
                      ),
                      if (eventEnded)
                        TextButton.icon(
                          onPressed: isWorking ? null : () => _markNoShows(context, ref),
                          icon: const Icon(Icons.person_off_outlined, size: 18),
                          label: const Text('Mark no-shows'),
                        ),
                      if (eventEnded)
                        TextButton.icon(
                          onPressed: isWorking ? null : () => _issueCertificates(context, ref),
                          icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                          label: const Text('Issue certificates'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  needle.isEmpty
                      ? '$checkedIn of ${attendees.length} checked in'
                      : '${visible.length} match${visible.length == 1 ? '' : 'es'} · $checkedIn of ${attendees.length} checked in',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'No one matches “${_query.trim()}”.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
                      ),
                    ),
                  )
                else
                  ...visible.map((a) => _AttendeeTile(
                        attendee: a,
                        isWorking: isWorking,
                        onCheckIn: () => _checkIn(context, ref, a),
                        onUndo: () => _undo(context, ref, a),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _undo(BuildContext context, WidgetRef ref, EventAttendee attendee) async {
    final ok = await confirmDestructiveAction(
      context,
      title: 'Undo check-in?',
      message: '${attendee.name} will be marked as not checked in and the attendance points are taken back.',
      confirmLabel: 'Undo',
    );
    if (!ok || !context.mounted) return;
    final error = await ref.read(eventActionsControllerProvider.notifier).undoCheckIn(eventId, attendee.userId);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Check-in undone for ${attendee.name}.',
      errorMessage: error,
    );
  }

  Future<void> _issueCertificates(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDestructiveAction(
      context,
      title: 'Issue certificates?',
      message: 'Everyone who was checked in receives a certificate and +50 points. This cannot be undone.',
      confirmLabel: 'Issue',
    );
    if (!ok || !context.mounted) return;
    final (count, error) = await ref.read(eventActionsControllerProvider.notifier).issueCertificates(eventId);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: count == 0 ? 'Everyone already has a certificate.' : 'Issued $count certificate${count == 1 ? '' : 's'}.',
      errorMessage: error,
    );
  }

  Future<void> _markNoShows(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDestructiveAction(
      context,
      title: 'Mark no-shows?',
      message: 'Everyone registered who was not checked in will be marked as a no-show.',
      confirmLabel: 'Mark no-shows',
    );
    if (!ok || !context.mounted) return;
    final (count, error) = await ref.read(eventActionsControllerProvider.notifier).markNoShows(eventId);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: count == 0 ? 'No one to mark.' : 'Marked $count no-show${count == 1 ? '' : 's'}.',
      errorMessage: error,
    );
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref, EventAttendee attendee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check in manually?'),
        content: Text('Confirm ${attendee.name} is physically at the event. Prefer scanning their QR code when possible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Check in')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(eventActionsControllerProvider.notifier).checkInMember(eventId, attendee.userId);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: '${attendee.name} checked in.',
      errorMessage: error,
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  const _AttendeeTile({
    required this.attendee,
    required this.isWorking,
    required this.onCheckIn,
    required this.onUndo,
  });

  final EventAttendee attendee;
  final bool isWorking;
  final VoidCallback onCheckIn;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: attendee.avatarUrl != null ? NetworkImage(attendee.avatarUrl!) : null,
        child: attendee.avatarUrl == null ? const Icon(Icons.person_outline_rounded) : null,
      ),
      title: Text(attendee.name),
      subtitle: Text(
        attendee.isCheckedIn
            ? 'Checked in ${DateFormatter.dateTime(attendee.checkedInAt!)} · ${attendee.method == 'qr' ? 'QR scan' : 'manual'}'
            : (attendee.studentNumber != null ? 'Student no. ${attendee.studentNumber}' : 'Registered'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
      ),
      trailing: attendee.isCheckedIn
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge.success('Present'),
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  tooltip: 'Undo check-in',
                  onPressed: isWorking ? null : onUndo,
                ),
              ],
            )
          : (attendee.isNoShow
              ? StatusBadge.alert('No-show')
              : TextButton(onPressed: isWorking ? null : onCheckIn, child: const Text('Check in'))),
    );
  }
}
