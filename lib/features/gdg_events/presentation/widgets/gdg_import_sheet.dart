import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/gdg_event.dart';
import '../providers/gdg_providers.dart';

/// Officer picker: upcoming events of our own GDG chapter, so an event that
/// already exists on gdg.community.dev doesn't have to be typed in again.
/// Resolves to the chosen [GdgEvent] (list-level data; the caller loads the
/// full detail).
class GdgImportSheet extends ConsumerWidget {
  const GdgImportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(gdgOwnUpcomingEventsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import from GDG', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pick an upcoming event from our chapter to fill in the form.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: eventsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text('Could not reach gdg.community.dev. Try again in a moment.'),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        'No upcoming events found for our chapter. Mark our chapter under '
                        'Events → GDG Community → Chapters first.',
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(DateFormatter.dateTime(e.startAt)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(e),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
