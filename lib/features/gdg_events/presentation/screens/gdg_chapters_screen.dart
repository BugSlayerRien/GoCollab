import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/gdg_providers.dart';

/// Officer-only: which GDG chapters feed the in-app "GDG Community" events,
/// and which of them is our own (its events can be imported into GoCollab).
class GdgChaptersScreen extends ConsumerWidget {
  const GdgChaptersScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    var isOwn = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Add a GDG chapter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chapter ID',
                  helperText: 'The number gdg.community.dev uses for the chapter.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  helperText: 'Left blank, it is read from the chapter’s events.',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: isOwn,
                onChanged: (v) => setState(() => isOwn = v ?? false),
                title: const Text('This is our chapter'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Add')),
          ],
        ),
      ),
    );

    final id = int.tryParse(idController.text.trim());
    final name = nameController.text;
    idController.dispose();
    nameController.dispose();
    if (confirmed != true || !context.mounted) return;
    if (id == null) {
      showActionFeedback(context, success: false, successMessage: '', errorMessage: 'Enter a numeric chapter ID.');
      return;
    }

    final error = await ref.read(gdgChapterActionsProvider.notifier).add(chapterId: id, name: name, isOwn: isOwn);
    if (!context.mounted) return;
    showActionFeedback(context, success: error == null, successMessage: 'Chapter added.', errorMessage: error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(gdgChaptersProvider);
    final isWorking = ref.watch(gdgChapterActionsProvider);
    final myChapterId = ref.watch(currentUserProvider).valueOrNull?.chapterId;

    return Scaffold(
      appBar: AppBar(title: const Text('GDG chapters')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isWorking ? null : () => _add(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Chapter'),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorStateView(
          message: 'Could not load chapters.',
          onRetry: () => ref.invalidate(gdgChaptersProvider),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return const EmptyState(
              icon: Icons.public_rounded,
              title: 'No chapters yet',
              message: 'Add the chapters whose events members should see.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = chapters[i];
              final canEdit = c.ownerChapterId != null && c.ownerChapterId == myChapterId;
              return ListTile(
                title: Text(c.name),
                subtitle: Text(
                  'ID ${c.id}${c.isOwn ? ' · our chapter' : ''}${canEdit ? '' : ' · managed by another chapter'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                ),
                leading: Icon(c.isOwn ? Icons.star_rounded : Icons.groups_outlined),
                onTap: canEdit ? () => ref.read(gdgChapterActionsProvider.notifier).setOwn(c.id, !c.isOwn) : null,
                trailing: !canEdit
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove',
                  onPressed: () async {
                    final ok = await confirmDestructiveAction(
                      context,
                      title: 'Remove chapter?',
                      message: 'Its events will no longer appear in the GDG feed.',
                      confirmLabel: 'Remove',
                    );
                    if (!ok || !context.mounted) return;
                    final error = await ref.read(gdgChapterActionsProvider.notifier).remove(c.id);
                    if (!context.mounted) return;
                    showActionFeedback(
                      context,
                      success: error == null,
                      successMessage: 'Chapter removed.',
                      errorMessage: error,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
