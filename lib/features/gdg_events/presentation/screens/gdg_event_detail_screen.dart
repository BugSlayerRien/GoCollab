import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/in_app_browser.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../events/presentation/widgets/event_map_preview.dart';
import '../providers/gdg_providers.dart';

/// A GDG chapter event shown fully inside GoCollab: details, venue map and
/// description are rendered natively. Only the final registration step —
/// which lives on GDG's own site — opens in the in-app browser.
class GdgEventDetailScreen extends ConsumerWidget {
  const GdgEventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(gdgEventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('GDG event')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorStateView(
          message: 'Could not load this GDG event.',
          onRetry: () => ref.invalidate(gdgEventDetailProvider(eventId)),
        ),
        data: (event) {
          final venue = [event.venueName, event.venueAddress].whereType<String>().join(' • ');
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (event.bannerUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: event.bannerUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  StatusBadge.info('GDG Community'),
                  const SizedBox(width: AppSpacing.xs),
                  if (event.isVirtual) StatusBadge.pending('Online'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                event.chapterName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.appTextSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(icon: Icons.schedule_rounded, text: DateFormatter.range(event.startAt, event.endAt)),
              if (event.isVirtual)
                const _InfoRow(icon: Icons.videocam_outlined, text: 'Online event')
              else if (venue.isNotEmpty)
                _InfoRow(icon: Icons.place_outlined, text: venue),
              if (event.capacity != null && event.capacity! > 0)
                _InfoRow(icon: Icons.groups_outlined, text: 'Capacity ${event.capacity}'),
              if (event.descriptionHtml != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('About this event', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                HtmlWidget(
                  event.descriptionHtml!,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  onTapUrl: (url) {
                    openInApp(context, url);
                    return true;
                  },
                ),
              ],
              if (event.hasLocation && !event.isVirtual) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Venue', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                LocationMapPreview(
                  latitude: event.latitude!,
                  longitude: event.longitude!,
                  label: event.venueName ?? event.title,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Register on GDG',
                icon: Icons.open_in_new_rounded,
                onPressed: () => openInApp(context, event.url, title: event.title),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Event information from gdg.community.dev. Registration is handled by the GDG chapter.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.appTextSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
