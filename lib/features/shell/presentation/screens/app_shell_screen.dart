import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../dashboard/presentation/screens/officer_dashboard_screen.dart';
import '../../../events/presentation/screens/events_list_screen.dart';
import '../../../opportunities/presentation/screens/opportunities_list_screen.dart';
import '../../../partnerships/presentation/screens/partners_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/shell_providers.dart';
import '../widgets/prismatic_nav_bar.dart';

/// The single post-auth entry point (`/`). Renders a role-aware bottom
/// navigation shell: Members get the 5-tab experience from the spec (Home,
/// Opportunities, Events, Community, Profile); Officers get the extended
/// tab set that adds the Analytics and Partnerships management modules
/// ("Officer Dashboard may have additional tabs").
///
/// Each tab's root screen is kept alive in an [IndexedStack] so switching
/// tabs preserves scroll position / in-flight requests instead of
/// rebuilding from scratch every time.
class AppShellScreen extends ConsumerWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = user?.role == UserRole.officer;
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    final destinations = isOfficer ? _officerDestinations : _memberDestinations;
    final screens = isOfficer ? _officerScreens : _memberScreens;

    final safeIndex = selectedIndex >= screens.length ? 0 : selectedIndex;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: PrismaticNavBar(
        selectedIndex: safeIndex,
        destinations: destinations,
        onDestinationSelected: (index) => ref.read(selectedTabIndexProvider.notifier).state = index,
      ),
    );
  }
}

const _memberDestinations = [
  NavDestinationSpec(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
  NavDestinationSpec(icon: Icons.work_outline_rounded, selectedIcon: Icons.work_rounded, label: 'Opportunities'),
  NavDestinationSpec(icon: Icons.event_outlined, selectedIcon: Icons.event_rounded, label: 'Events'),
  NavDestinationSpec(icon: Icons.groups_outlined, selectedIcon: Icons.groups_rounded, label: 'Community'),
  NavDestinationSpec(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
];

final _memberScreens = const [
  DashboardScreen(),
  OpportunitiesListScreen(),
  EventsListScreen(),
  CommunityScreen(),
  ProfileScreen(),
];

const _officerDestinations = [
  NavDestinationSpec(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
  NavDestinationSpec(icon: Icons.event_outlined, selectedIcon: Icons.event_rounded, label: 'Events'),
  NavDestinationSpec(icon: Icons.groups_outlined, selectedIcon: Icons.groups_rounded, label: 'Community'),
  NavDestinationSpec(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart_rounded, label: 'Analytics'),
  NavDestinationSpec(icon: Icons.handshake_outlined, selectedIcon: Icons.handshake_rounded, label: 'Partners'),
  NavDestinationSpec(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
];

final _officerScreens = const [
  OfficerDashboardScreen(),
  EventsListScreen(),
  CommunityScreen(),
  AnalyticsScreen(),
  PartnersListScreen(),
  ProfileScreen(),
];
