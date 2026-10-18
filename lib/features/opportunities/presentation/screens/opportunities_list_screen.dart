import '../../../shell/presentation/widgets/collapsible_sidebar.dart';
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
import '../widgets/google_programs_section.dart';
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
  bool _showHistory = false; // closed or past-deadline opportunities

  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync =
        _savedOnly ? ref.watch(savedOpportunitiesProvider) : ref.watch(opportunitiesListProvider);
    ref.watch(savedOpportunityControllerProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      appBar: AppBar(
        leading: sidebarMenuLeading(ref),
        title: Text(_showHistory ? 'Opportunity history' : 'Career Hub'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.work_outline_rounded : Icons.history_rounded),
            tooltip: _showHistory ? 'Open opportunities' : 'History (closed)',
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
          IconButton(
            icon: Icon(_savedOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            tooltip: 'Saved opportunities',
            onPressed: () => setState(() => _savedOnly = !_savedOnly),
          ),
        ],
      ),
      floatingActionButton: isOfficer && !_showHistory
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
            // Open ones by default; closed or past-deadline ones live in History.
            final byState = opportunities.where((o) => _showHistory ? !o.isOpen : o.isOpen);
            final filtered = _filter == null ? byState.toList() : byState.where((o) => o.type == _filter).toList();
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
                if (!_savedOnly && !_showHistory) const GoogleProgramsSection(),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: _savedOnly ? Icons.bookmark_border_rounded : Icons.work_outline_rounded,
                          title: _showHistory
                              ? 'No closed opportunities'
                              : (_savedOnly ? 'No saved opportunities yet' : 'No opportunities found'),
                          message: _showHistory
                              ? 'Opportunities move here once they close or pass their deadline.'
                              : (_savedOnly
                                  ? 'Bookmark internships, scholarships, or hackathons to find them here.'
                                  : 'New career opportunities are posted regularly — check back soon.'),
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
