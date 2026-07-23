import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';
import '../widgets/create_opportunity_sheet.dart';
import '../widgets/opportunity_card.dart';

class OpportunitiesListScreen extends ConsumerStatefulWidget {
  const OpportunitiesListScreen({super.key});

  @override
  ConsumerState<OpportunitiesListScreen> createState() => _OpportunitiesListScreenState();
}

class _OpportunitiesListScreenState extends ConsumerState<OpportunitiesListScreen>
    with SingleTickerProviderStateMixin {
  OpportunityType? _filter;
  bool _savedOnly = false;

  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync =
        _savedOnly ? ref.watch(savedOpportunitiesProvider) : ref.watch(opportunitiesListProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Hub'),
        actions: [
          IconButton(
            icon: Icon(_savedOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            tooltip: 'Saved opportunities',
            onPressed: () => setState(() => _savedOnly = !_savedOnly),
          ),
        ],
      ),
      floatingActionButton: isOfficer
          ? FloatingActionButton.extended(
              onPressed: () => showCreateOpportunitySheet(context, postedBy: currentUser!.id),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_savedOnly ? savedOpportunitiesProvider : opportunitiesListProvider),
        child: opportunitiesAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 110),
          ),
          error: (error, _) => ErrorStateView(
            message: 'Could not load opportunities. Pull down to retry.',
            onRetry: () => ref.invalidate(_savedOnly ? savedOpportunitiesProvider : opportunitiesListProvider),
          ),
          data: (opportunities) {
            final filtered =
                _filter == null ? opportunities : opportunities.where((o) => o.type == _filter).toList();
            return Column(
              children: [
                if (!_savedOnly)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        _chip(label: 'All', value: null),
                        ...OpportunityType.values.map((t) => _chip(label: t.label, value: t)),
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: _savedOnly ? Icons.bookmark_border_rounded : Icons.work_outline_rounded,
                          title: _savedOnly ? 'No saved opportunities yet' : 'No opportunities found',
                          message: _savedOnly
                              ? 'Bookmark internships, scholarships, or hackathons to find them here.'
                              : 'New career opportunities are posted regularly — check back soon.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final opportunity = filtered[index];
                            return OpportunityCard(
                              opportunity: opportunity,
                              onTap: () => context.push('/opportunities/${opportunity.id}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip({required String label, required OpportunityType? value}) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
