import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/chapter_providers.dart';
import '../providers/admin_providers.dart';

/// Appoint / remove officers and move members between chapters.
class AdminMembersScreen extends ConsumerWidget {
  const AdminMembersScreen({super.key});

  Future<void> _moveChapter(BuildContext context, WidgetRef ref, AdminMember m, List<ChapterOption> chapters) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Move ${m.fullName} to…', style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final c in chapters.where((c) => c.isActive))
              ListTile(
                leading: Icon(c.id == m.chapterId ? Icons.check_circle_rounded : Icons.apartment_rounded),
                title: Text(c.name),
                subtitle: Text(c.campus),
                onTap: () => Navigator.of(sheetContext).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == m.chapterId || !context.mounted) return;
    final error = await ref.read(adminActionsProvider.notifier).assignChapter(m.id, picked);
    if (!context.mounted) return;
    showActionFeedback(context, success: error == null, successMessage: 'Chapter updated.', errorMessage: error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(adminMembersProvider);
    final chapters = ref.watch(chapterOptionsProvider).valueOrNull ?? const <ChapterOption>[];
    final names = {for (final c in chapters) c.id: c.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Members & roles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search name or email',
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(adminMemberQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorStateView(
                message: 'Could not load members.',
                onRetry: () => ref.invalidate(adminMembersProvider),
              ),
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.search_off_rounded, title: 'No members found', message: 'Try another search.')
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final m = list[i];
                        final role = m.isAdmin ? 'Admin' : (m.isOfficer ? 'Officer' : 'Member');
                        return ListTile(
                          leading: Icon(m.isOfficer || m.isAdmin ? Icons.shield_rounded : Icons.person_outline_rounded),
                          title: Text(m.fullName),
                          subtitle: Text(
                            '${m.email}\n$role · ${names[m.chapterId] ?? 'No chapter'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                          ),
                          isThreeLine: true,
                          trailing: m.isAdmin
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'chapter') {
                                      await _moveChapter(context, ref, m, chapters);
                                      return;
                                    }
                                    final promote = action == 'promote';
                                    final ok = await confirmDestructiveAction(
                                      context,
                                      title: promote ? 'Make officer?' : 'Remove officer role?',
                                      message: promote
                                          ? '${m.fullName} will manage events, verification and claims for their chapter.'
                                          : '${m.fullName} becomes a regular member again.',
                                      confirmLabel: promote ? 'Make officer' : 'Remove',
                                    );
                                    if (!ok || !context.mounted) return;
                                    final error =
                                        await ref.read(adminActionsProvider.notifier).setRole(m.id, promote ? 2 : 1);
                                    if (!context.mounted) return;
                                    showActionFeedback(
                                      context,
                                      success: error == null,
                                      successMessage: promote ? 'Officer appointed.' : 'Officer role removed.',
                                      errorMessage: error,
                                    );
                                  },
                                  itemBuilder: (_) => [
                                    if (!m.isOfficer) const PopupMenuItem(value: 'promote', child: Text('Make officer')),
                                    if (m.isOfficer) const PopupMenuItem(value: 'demote', child: Text('Remove officer role')),
                                    const PopupMenuItem(value: 'chapter', child: Text('Move to chapter…')),
                                  ],
                                ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
