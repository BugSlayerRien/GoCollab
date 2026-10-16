import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
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
                const SizedBox(height: AppSpacing.md),
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
                      )),
              ],
            );
          },
        ),
      ),
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
  const _AttendeeTile({required this.attendee, required this.isWorking, required this.onCheckIn});

  final EventAttendee attendee;
  final bool isWorking;
  final VoidCallback onCheckIn;

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
          ? StatusBadge.success('Present')
          : TextButton(onPressed: isWorking ? null : onCheckIn, child: const Text('Check in')),
    );
  }
}
