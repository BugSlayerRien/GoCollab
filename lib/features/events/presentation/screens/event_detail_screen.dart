import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/animations/prismatic_background.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';
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
        error: (error, _) => ErrorStateView(
          message: 'Could not load this event.',
          onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        ),
        data: (event) => _EventDetailBody(event: event, isOfficer: isOfficer),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({required this.event, required this.isOfficer});

  final Event event;
  final bool isOfficer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(eventActionsControllerProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.surfaceWhite,
          foregroundColor: AppColors.textPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: PrismaticBackground(opacity: 0.18, loopDuration: const Duration(seconds: 15)),
          ),
          actions: [
            if (isOfficer)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scan attendance',
                onPressed: () => context.push('/events/${event.id}/check-in'),
              ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  StatusBadge.pending(event.category.label),
                  const SizedBox(width: AppSpacing.xs),
                  if (event.isRegistered) StatusBadge.success('You are registered'),
                  if (!event.registrationOpen && !event.isRegistered) StatusBadge.alert('Registration closed'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(icon: Icons.schedule_rounded, text: DateFormatter.range(event.startAt, event.endAt)),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: event.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                text: event.isOnline ? (event.onlineUrl ?? 'Online event') : (event.venueName ?? 'Venue TBA'),
              ),
              if (event.capacity != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(icon: Icons.groups_outlined, text: '${event.registeredCount} / ${event.capacity} registered'),
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
              const SizedBox(height: AppSpacing.xxl),
              if (!isOfficer)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: event.isRegistered ? 'Cancel registration' : 'Register now',
                        variant: event.isRegistered ? AppButtonVariant.outlined : AppButtonVariant.filled,
                        color: event.isRegistered ? AppColors.googleRed : null,
                        isLoading: isSubmitting,
                        onPressed: (event.isRegistered || event.registrationOpen)
                            ? () => _handleRegistration(context, ref)
                            : null,
                      ),
                    ),
                    if (event.isRegistered) ...[
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        onPressed: () => CalendarService.addEventToDeviceCalendar(event),
                        icon: const Icon(Icons.calendar_month_rounded),
                        tooltip: 'Add to calendar',
                      ),
                    ],
                  ],
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(eventActionsControllerProvider.notifier);
    final success = event.isRegistered ? await controller.cancel(event.id) : await controller.register(event.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (event.isRegistered ? 'Registration cancelled.' : "You're registered! See you there.")
              : 'Something went wrong. Please try again.',
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
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
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
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
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
