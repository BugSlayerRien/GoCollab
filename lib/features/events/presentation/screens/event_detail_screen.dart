import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/widgets/in_app_browser.dart';
import '../../../../core/animations/prismatic_background.dart';
import '../../../../core/theme/app_colors.dart';
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
import '../../../verification/presentation/widgets/verification_prompt_card.dart';
import '../../data/ticket_cache.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';
import '../widgets/create_event_sheet.dart';
import '../widgets/event_map_preview.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FutureBuilder<(String, String)?>(
          future: TicketCache.load(eventId),
          builder: (context, snapshot) {
            final ticket = snapshot.data;
            if (ticket == null) {
              return ErrorStateView(
                message: 'Could not load this event.',
                onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
              );
            }
            return _OfflineTicket(
              title: ticket.$1,
              qrCode: ticket.$2,
              onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
            );
          },
        ),
        data: (event) => _EventDetailBody(
          event: event,
          isOfficer: isOfficer,
          canManage: isOfficer && currentUser != null && event.createdBy == currentUser.id,
          isVerified: currentUser?.isVerified ?? false,
        ),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({
    required this.event,
    required this.isOfficer,
    required this.canManage,
    required this.isVerified,
  });

  final Event event;
  final bool isOfficer;
  final bool canManage;
  final bool isVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(eventActionsControllerProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: context.appSurface,
          foregroundColor: context.appTextPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: event.bannerUrl != null && event.bannerUrl!.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.bannerUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => PrismaticBackground(
                          opacity: 0.18,
                          loopDuration: const Duration(seconds: 15),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : PrismaticBackground(opacity: 0.18, loopDuration: const Duration(seconds: 15)),
          ),
          actions: [
            if (canManage)
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: 'Attendance list',
                onPressed: () => context.push('/events/${event.id}/attendees'),
              ),
            if (canManage)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scan attendance',
                onPressed: () => context.push('/events/${event.id}/check-in'),
              ),
            if (canManage)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => showEventEditorSheet(context, existing: event),
              ),
            if (canManage)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await confirmDestructiveAction(
                    context,
                    title: 'Delete event?',
                    message: 'This permanently removes the event and its registrations.',
                  );
                  if (!confirmed) return;
                  final error = await ref.read(eventActionsControllerProvider.notifier).deleteEvent(event.id);
                  if (!context.mounted) return;
                  showActionFeedback(
                    context,
                    success: error == null,
                    successMessage: 'Event deleted.',
                    errorMessage: error,
                  );
                  if (error == null) context.pop();
                },
              ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge.pending(event.category.label),
                  if (event.isAttended)
                    StatusBadge.success('Attended ✓')
                  else if (event.isRegistered)
                    StatusBadge.success('You are registered'),
                  if (!event.registrationOpen && !event.isRegistered) StatusBadge.alert('Registration closed'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
              if (event.creator != null) ...[
                const SizedBox(height: AppSpacing.sm),
                CreatorAttribution(label: 'Organizer', creator: event.creator),
              ],
              const SizedBox(height: AppSpacing.md),
              _InfoRow(icon: Icons.schedule_rounded, text: DateFormatter.range(event.startAt, event.endAt)),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: event.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                text: event.isOnline
                    ? (event.onlineUrl ?? 'Online event')
                    : _venueLabel(event),
              ),
              if (event.capacity != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(icon: Icons.groups_outlined, text: '${event.registeredCount} / ${event.capacity} registered'),
              ],
              if (event.partnerId != null && event.partnerName != null) ...[
                const SizedBox(height: AppSpacing.md),
                _PartnerRow(
                  name: event.partnerName!,
                  logoUrl: event.partnerLogoUrl,
                  onTap: () => _showPartner(context, event),
                ),
              ],
              if (event.isOnline && event.onlineUrl != null && event.onlineUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Join online',
                  icon: Icons.videocam_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _joinOnline(context, event.onlineUrl!.trim()),
                ),
              ],
              if (event.gdgEventUrl != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openInApp(context, event.gdgEventUrl!, title: event.title),
                    icon: const Icon(Icons.public_rounded, size: 18),
                    label: const Text('Also on GDG community'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('About this event', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(event.description, style: Theme.of(context).textTheme.bodyMedium),
              if (event.hasLocation) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Venue', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                LocationMapPreview(
                  latitude: event.latitude!,
                  longitude: event.longitude!,
                  label: event.venueName ?? event.title,
                ),
              ],
              if (event.isRegistered && event.myQrCode != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _MyQrCodeCard(qrData: event.myQrCode!, eventTitle: event.title),
              ],
              if (event.isAttended && event.feedbackFormUrl != null && event.feedbackFormUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Give feedback',
                  icon: Icons.rate_review_outlined,
                  onPressed: () => openInApp(context, event.feedbackFormUrl!.trim(), title: 'Event feedback'),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (!isOfficer) ...[
                // Unverified members can browse everything but cannot join.
                // The real gate is the RLS policy on event_registrations —
                // this card just explains why the button is disabled.
                if (!isVerified && !event.isRegistered) const VerificationPromptCard(),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: event.isRegistered ? 'Cancel registration' : 'Register now',
                        variant: event.isRegistered ? AppButtonVariant.outlined : AppButtonVariant.filled,
                        color: event.isRegistered ? AppColors.googleRed : null,
                        isLoading: isSubmitting,
                        onPressed: event.isRegistered
                            ? (!event.isPast ? () => _handleRegistration(context, ref) : null)
                            : (event.registrationOpen && isVerified
                                ? () => _handleRegistration(context, ref)
                                : null),
                      ),
                    ),
                  ],
                ),
                if (event.isRegistered) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _GoogleCalendarSyncCard(event: event),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }

  /// Video-call links open the Meet/Zoom/Teams app (they need the camera, mic
  /// and the user's sign-in); anything else opens in the in-app browser.
  Future<void> _joinOnline(BuildContext context, String url) async {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    final isCall = host.contains('meet.google.com') || host.contains('zoom.us') || host.contains('teams.');
    if (isCall) {
      await openExternal(context, url);
    } else if (context.mounted) {
      await openInApp(context, url, title: event.title);
    }
  }

  Future<void> _handleRegistration(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(eventActionsControllerProvider.notifier);
    final error = event.isRegistered ? await controller.cancel(event.id) : await controller.register(event.id);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: event.isRegistered ? 'Registration cancelled.' : "You're registered! See you there.",
      errorMessage: error,
    );
  }

  String _venueLabel(Event event) {
    if (event.venueName != null && event.venueName!.trim().isNotEmpty) {
      if (event.venueAddress != null && event.venueAddress!.trim().isNotEmpty) {
        return '${event.venueName} • ${event.venueAddress}';
      }
      return event.venueName!;
    }
    if (event.venueAddress != null && event.venueAddress!.trim().isNotEmpty) {
      return event.venueAddress!;
    }
    return 'Venue TBA';
  }
}

void _showPartner(BuildContext context, Event event) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (event.partnerLogoUrl != null && event.partnerLogoUrl!.isNotEmpty)
                CircleAvatar(radius: 24, backgroundImage: CachedNetworkImageProvider(event.partnerLogoUrl!))
              else
                const CircleAvatar(radius: 24, child: Icon(Icons.handshake_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(event.partnerName ?? 'Partner', style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            event.partnerDescription?.trim().isNotEmpty == true
                ? event.partnerDescription!
                : 'Proud partner of this GDGoC event.',
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          if (event.partnerWebsite?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Visit website',
              icon: Icons.open_in_new_rounded,
              variant: AppButtonVariant.outlined,
              onPressed: () => openInApp(context, event.partnerWebsite!, title: event.partnerName),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.name, this.logoUrl, this.onTap});
  final String name;
  final String? logoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoUrl != null && logoUrl!.isNotEmpty)
            CircleAvatar(radius: 10, backgroundImage: CachedNetworkImageProvider(logoUrl!))
          else
            const Icon(Icons.handshake_outlined, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'In partnership with $name',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, size: 16),
        ],
      ),
    ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.appTextSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _GoogleCalendarSyncCard extends ConsumerWidget {
  const _GoogleCalendarSyncCard({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(gcalSyncStatusProvider(event.id));
    final calendarAccessAsync = ref.watch(googleCalendarAccessProvider);
    final isWorking = ref.watch(gcalActionsControllerProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: syncStatusAsync.when(
        loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => _buildRow(
          context,
          ref,
          isSynced: false,
          hasCalendarAccess: calendarAccessAsync.valueOrNull ?? false,
          isWorking: isWorking,
        ),
        data: (isSynced) => _buildRow(
          context,
          ref,
          isSynced: isSynced,
          hasCalendarAccess: calendarAccessAsync.valueOrNull ?? false,
          isWorking: isWorking,
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    WidgetRef ref, {
    required bool isSynced,
    required bool hasCalendarAccess,
    required bool isWorking,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSynced ? Icons.event_available_rounded : Icons.event_rounded,
              color: isSynced ? AppColors.googleGreen : AppColors.googleBlue,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isSynced ? 'Synced to Google Calendar' : 'Google Calendar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasCalendarAccess && !isSynced)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connect your Google account to add events to your calendar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Connect Google Calendar',
                icon: Icons.link_rounded,
                isLoading: isWorking,
                onPressed: () => _connect(context, ref),
              ),
            ],
          )
        else if (!isSynced)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Add to Google Calendar',
              icon: Icons.add_rounded,
              isLoading: isWorking,
              onPressed: () => _add(context, ref),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Update',
                  icon: Icons.sync_rounded,
                  variant: AppButtonVariant.outlined,
                  isLoading: isWorking,
                  onPressed: () => _update(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Remove',
                  icon: Icons.delete_outline_rounded,
                  variant: AppButtonVariant.outlined,
                  color: AppColors.googleRed,
                  isLoading: isWorking,
                  onPressed: () => _remove(context, ref),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(gcalActionsControllerProvider.notifier);
    final error = await controller.connectGoogleCalendar();
    if (!context.mounted) return;
    if (error != null) {
      showActionFeedback(
        context,
        success: false,
        successMessage: '',
        errorMessage: error,
      );
    }
    // On success the browser redirects to Google OAuth; no snackbar needed.
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(gcalActionsControllerProvider.notifier);
    final error = await controller.addToCalendar(event);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Event added to your Google Calendar.',
      errorMessage: error,
    );
  }

  Future<void> _update(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(gcalActionsControllerProvider.notifier);
    final error = await controller.updateCalendarEvent(event);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Google Calendar event updated.',
      errorMessage: error,
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Remove from Google Calendar?',
      message: 'This will delete the event from your Google Calendar but keep your GoCollab registration.',
    );
    if (!confirmed) return;
    final controller = ref.read(gcalActionsControllerProvider.notifier);
    final error = await controller.removeFromCalendar(event.id);
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Event removed from your Google Calendar.',
      errorMessage: error,
    );
  }
}

class _MyQrCodeCard extends StatelessWidget {
  const _MyQrCodeCard({required this.qrData, required this.eventTitle});

  final String qrData;
  final String eventTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Text('Your check-in QR code', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Show this at the venue for attendance check-in.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: QrImageView(data: qrData, size: 180, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Shown when the event cannot be loaded but a ticket was saved earlier.
class _OfflineTicket extends StatelessWidget {
  const _OfflineTicket({required this.title, required this.qrCode, required this.onRetry});

  final String title;
  final String qrCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: BackButton(onPressed: () => Navigator.of(context).maybePop())),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text('You are offline. Showing your saved ticket.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MyQrCodeCard(qrData: qrCode, eventTitle: title),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
