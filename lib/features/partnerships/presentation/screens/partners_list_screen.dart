import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/partnership_providers.dart';
import '../widgets/create_partner_sheet.dart';
import '../widgets/partner_card.dart';

/// Officer-only "Partnership Management" module (#6): partner directory,
/// with sponsorship tracking / meetings / communications drilled into from
/// each partner's detail screen.
class PartnersListScreen extends ConsumerWidget {
  const PartnersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(partnersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partnerships')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreatePartnerSheet(context),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add partner'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(partnersListProvider),
        child: partnersAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 80),
          ),
          error: (e, _) => ErrorStateView(
            message: 'Could not load partners.',
            onRetry: () => ref.invalidate(partnersListProvider),
          ),
          data: (partners) {
            if (partners.isEmpty) {
              return const EmptyState(
                icon: Icons.handshake_outlined,
                title: 'No partners yet',
                message: 'Add sponsors, academic partners, or government agencies to get started.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: partners.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final partner = partners[index];
                return PartnerCard(partner: partner, onTap: () => context.push('/partners/${partner.id}'));
              },
            );
          },
        ),
      ),
    );
  }
}
