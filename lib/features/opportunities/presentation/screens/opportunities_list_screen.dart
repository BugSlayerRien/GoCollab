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

enum _OpportunityView { all, saved, applied }

class _OpportunitiesListScreenState extends ConsumerState<OpportunitiesListScreen>
    with SingleTickerProviderStateMixin {
  OpportunityType? _filter;
  _OpportunityView _view = _OpportunityView.all;

  @override
  Widget build(BuildContext context) {
    final opportunitiesAsync = switch (_view) {
      _OpportunityView.all => ref.watch(opportunitiesListProvider),
      _OpportunityView.saved => ref.watch(savedOpportunitiesProvider),
      _OpportunityView.applied => ref.watch(appliedOpportunitiesProvider),
    };
    ref.watch(savedOpportunityControllerProvider);
    ref.watch(applyOpportunityControllerProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Hub'),
        actions: [
          IconButton(
            icon: Icon(_view == _OpportunityView.applied ? Icons.fact_check_rounded : Icons.fact_check_outlined),
            tooltip: 'My applications',
            onPressed: () => setState(
              () => _view = _view == _OpportunityView.applied ? _OpportunityView.all : _OpportunityView.applied,
            ),
          ),
          IconButton(
            icon: Icon(_view == _OpportunityView.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            tooltip: 'Saved opportunities',
            onPressed: () => setState(
              () => _view = _view == _OpportunityView.saved ? _OpportunityView.all : _OpportunityView.saved,
            ),
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
        onRefresh: () async => ref.invalidate(switch (_view) {
          _OpportunityView.all => opportunitiesListProvider,
          _OpportunityView.saved => savedOpportunitiesProvider,
          _OpportunityView.applied => appliedOpportunitiesProvider,
        }),
        child: opportunitiesAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 110),
          ),
          error: (error, _) => ErrorStateView(
            message: 'Could not load opportunities. Pull down to retry.',
            onRetry: () => ref.invalidate(switch (_view) {
              _OpportunityView.all => opportunitiesListProvider,
              _OpportunityView.saved => savedOpportunitiesProvider,
              _OpportunityView.applied => appliedOpportunitiesProvider,
            }),
          ),
          data: (opportunities) {
            final filtered =
                _filter == null ? opportunities : opportunities.where((o) => o.type == _filter).toList();
            return Column(
              children: [
                if (_view == _OpportunityView.all)
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
                          icon: switch (_view) {
                            _OpportunityView.saved => Icons.bookmark_border_rounded,
                            _OpportunityView.applied => Icons.fact_check_outlined,
                            _OpportunityView.all => Icons.work_outline_rounded,
                          },
                          title: switch (_view) {
                            _OpportunityView.saved => 'No saved opportunities yet',
                            _OpportunityView.applied => 'No applications marked yet',
                            _OpportunityView.all => 'No opportunities found',
                          },
                          message: switch (_view) {
                            _OpportunityView.saved =>
                              'Bookmark internships, scholarships, or hackathons to find them here.',
                            _OpportunityView.applied =>
                              'After you apply on a partner site, use "Mark as applied" to keep a record and '
                                  'come back to it here.',
                            _OpportunityView.all => 'New career opportunities are posted regularly — check back soon.',
                          },
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
