import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/chapter_providers.dart';
import '../providers/admin_providers.dart';

class AdminChaptersScreen extends ConsumerWidget {
  const AdminChaptersScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final campus = TextEditingController();
    final region = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New chapter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Chapter name')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: campus, decoration: const InputDecoration(labelText: 'Campus / school')),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: region, decoration: const InputDecoration(labelText: 'Region (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Create')),
        ],
      ),
    );
    final n = name.text.trim();
    final c = campus.text.trim();
    final r = region.text.trim();
    name.dispose();
    campus.dispose();
    region.dispose();
    if (ok != true || !context.mounted) return;
    if (n.isEmpty || c.isEmpty) {
      showActionFeedback(context, success: false, successMessage: '', errorMessage: 'Name and campus are required.');
      return;
    }
    final error = await ref.read(adminActionsProvider.notifier).createChapter(name: n, campus: c, region: r);
    ref.invalidate(chapterOptionsProvider);
    if (!context.mounted) return;
    showActionFeedback(context, success: error == null, successMessage: 'Chapter created.', errorMessage: error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chapterOptionsProvider);
    final busy = ref.watch(adminActionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chapters')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => _create(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Chapter'),
      ),
      body: chapters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorStateView(
          message: 'Could not load chapters.',
          onRetry: () => ref.invalidate(chapterOptionsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(icon: Icons.apartment_rounded, title: 'No chapters', message: 'Create the first chapter.')
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = list[i];
                  return ListTile(
                    leading: Icon(c.isActive ? Icons.apartment_rounded : Icons.block_rounded),
                    title: Text(c.name),
                    subtitle: Text(
                      '${c.campus}${c.isActive ? '' : ' · inactive'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        String? error;
                        if (action == 'toggle') {
                          error = await ref.read(adminActionsProvider.notifier).setChapterActive(c.id, !c.isActive);
                        } else {
                          final ok = await confirmDestructiveAction(
                            context,
                            title: 'Delete chapter?',
                            message: 'Only chapters with no members can be deleted.',
                            confirmLabel: 'Delete',
                          );
                          if (!ok) return;
                          error = await ref.read(adminActionsProvider.notifier).deleteChapter(c.id);
                        }
                        ref.invalidate(chapterOptionsProvider);
                        if (!context.mounted) return;
                        showActionFeedback(context, success: error == null, successMessage: 'Done.', errorMessage: error);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'toggle', child: Text(c.isActive ? 'Deactivate' : 'Activate')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
