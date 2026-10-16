import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../verification/data/services/id_ocr_service.dart';
import '../../domain/entities/application_claim.dart';
import '../providers/claim_providers.dart';

/// Officer-only queue of "I applied externally" proofs. Built to stay usable
/// at volume: filter to one opportunity, tick many rows (or everything the
/// OCR check marked as genuine) and approve them in a single action. Opening
/// a row shows the proof for a careful single review.
class ApplicationClaimsScreen extends ConsumerStatefulWidget {
  const ApplicationClaimsScreen({super.key});

  @override
  ConsumerState<ApplicationClaimsScreen> createState() => _ApplicationClaimsScreenState();
}

class _ApplicationClaimsScreenState extends ConsumerState<ApplicationClaimsScreen> {
  String? _opportunityId;
  final Set<String> _selected = {};

  void _clearSelection() => setState(_selected.clear);

  Future<void> _bulk(List<ApplicationClaim> visible, {required bool approve, Set<String>? ids}) async {
    final targets = (ids ?? _selected).toList();
    if (targets.isEmpty) return;

    String? reason;
    if (approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Approve ${targets.length} claim${targets.length == 1 ? '' : 's'}?'),
          content: Text('Each member gets 10 points. Only approve proofs you are comfortable trusting without opening.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(d).pop(true), child: const Text('Approve')),
          ],
        ),
      );
      if (ok != true) return;
    } else {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Reject ${targets.length} claim${targets.length == 1 ? '' : 's'}?'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Reason', hintText: 'e.g. Screenshot is unreadable'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(d).pop(), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.googleRed),
              onPressed: () => Navigator.of(d).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null) return;
    }

    if (!mounted) return;
    var processed = 0;
    final error = await ref.read(claimActionsControllerProvider.notifier).reviewBulk(
          targets,
          approve: approve,
          reason: reason,
          onDone: (n) => processed = n,
        );
    if (!mounted) return;
    if (error == null) _clearSelection();
    showActionFeedback(
      context,
      success: error == null,
      successMessage: approve ? '$processed approved.' : '$processed rejected.',
      errorMessage: error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(pendingClaimSummaryProvider).valueOrNull ?? const [];
    final claimsAsync = ref.watch(pendingClaimsProvider(_opportunityId));
    final isWorking = ref.watch(claimActionsControllerProvider);

    final counts = <String, ({String title, int count})>{};
    for (final s in summary) {
      final current = counts[s.opportunityId];
      counts[s.opportunityId] = (title: s.title, count: (current?.count ?? 0) + 1);
    }
    final genuineIds = {
      for (final s in summary)
        if (s.ocrResult == 'matched' && (_opportunityId == null || s.opportunityId == _opportunityId)) s.id,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_selected.isEmpty ? 'Application claims' : '${_selected.length} selected'),
        actions: [if (_selected.isNotEmpty) IconButton(onPressed: _clearSelection, icon: const Icon(Icons.close_rounded))],
      ),
      body: Column(
        children: [
          if (counts.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text('All (${summary.length})'),
                      selected: _opportunityId == null,
                      onSelected: (_) => setState(() {
                        _opportunityId = null;
                        _selected.clear();
                      }),
                    ),
                  ),
                  for (final e in counts.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text('${e.value.title} (${e.value.count})'),
                        selected: _opportunityId == e.key,
                        onSelected: (_) => setState(() {
                          _opportunityId = e.key;
                          _selected.clear();
                        }),
                      ),
                    ),
                ],
              ),
            ),
          if (genuineIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isWorking ? null : () => _bulk(const [], approve: true, ids: genuineIds),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text('Approve all ${genuineIds.length} that look genuine (OCR)'),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pendingClaimsProvider);
                ref.invalidate(pendingClaimSummaryProvider);
              },
              child: claimsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => ErrorStateView(
                  message: 'Could not load claims.',
                  onRetry: () => ref.invalidate(pendingClaimsProvider),
                ),
                data: (claims) {
                  if (claims.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.redeem_rounded,
                        title: 'Nothing to review',
                        message: 'Proofs of external applications appear here when members claim their points.',
                      ),
                    ]);
                  }
                  final total = _opportunityId == null
                      ? summary.length
                      : (counts[_opportunityId]?.count ?? claims.length);
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: claims.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  total > claims.length
                                      ? 'Showing the oldest ${claims.length} of $total'
                                      : '${claims.length} pending',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  final all = claims.map((c) => c.id).toSet();
                                  if (_selected.containsAll(all)) {
                                    _selected.removeAll(all);
                                  } else {
                                    _selected.addAll(all);
                                  }
                                }),
                                child: Text(_selected.length == claims.length ? 'Clear' : 'Select all shown'),
                              ),
                            ],
                          ),
                        );
                      }
                      final claim = claims[i - 1];
                      return _ClaimRow(
                        claim: claim,
                        selected: _selected.contains(claim.id),
                        onToggle: () => setState(() {
                          if (!_selected.add(claim.id)) _selected.remove(claim.id);
                        }),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Reject (${_selected.length})',
                        variant: AppButtonVariant.outlined,
                        color: AppColors.googleRed,
                        isLoading: isWorking,
                        onPressed: () => _bulk(const [], approve: false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Approve (${_selected.length})',
                        isLoading: isWorking,
                        onPressed: () => _bulk(const [], approve: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ClaimRow extends ConsumerWidget {
  const _ClaimRow({required this.claim, required this.selected, required this.onToggle});

  final ApplicationClaim claim;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocr = OcrResult.fromKey(claim.ocrResult);
    return ListTile(
      leading: Checkbox(value: selected, onChanged: (_) => onToggle()),
      title: Text(claim.applicantName ?? 'Member', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${claim.opportunityTitle ?? 'Opportunity'} · ${DateFormatter.date(claim.submittedAt ?? claim.clickedAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: switch (ocr) {
        OcrResult.matched => StatusBadge.success('Genuine'),
        OcrResult.partial => StatusBadge.pending('Check'),
        OcrResult.mismatch => StatusBadge.alert('Mismatch'),
        OcrResult.notRun => StatusBadge.info('Manual'),
      },
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _ProofDialog(claim: claim),
      ),
    );
  }
}

/// Full-size proof with single approve / reject, for the careful cases.
class _ProofDialog extends ConsumerWidget {
  const _ProofDialog({required this.claim});
  final ApplicationClaim claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofAsync = claim.proofPath == null ? null : ref.watch(claimProofUrlProvider(claim.proofPath!));
    final isWorking = ref.watch(claimActionsControllerProvider);

    Future<void> decide(bool approve) async {
      final error = await ref.read(claimActionsControllerProvider.notifier).review(
            claim.id,
            approve: approve,
            reason: approve ? null : 'Proof not accepted',
          );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showActionFeedback(
        context,
        success: error == null,
        successMessage: approve ? 'Approved. 10 points awarded.' : 'Claim rejected.',
        errorMessage: error,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(claim.opportunityTitle ?? 'Opportunity', style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${claim.applicantName ?? 'Member'} · tapped Apply ${DateFormatter.dateTime(claim.clickedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: proofAsync == null
                  ? const SizedBox.shrink()
                  : proofAsync.when(
                      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const Text('Could not load proof.'),
                      data: (url) => InteractiveViewer(
                        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    variant: AppButtonVariant.outlined,
                    color: AppColors.googleRed,
                    isLoading: isWorking,
                    onPressed: () => decide(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: AppButton(label: 'Approve', isLoading: isWorking, onPressed: () => decide(true))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
