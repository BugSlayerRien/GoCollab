import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_chapters_screen.dart';
import '../../features/admin/presentation/screens/admin_members_screen.dart';
import '../../features/admin/presentation/screens/audit_log_screen.dart';
import '../../features/application_claims/presentation/screens/application_claims_screen.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/calendar/presentation/screens/my_calendar_screen.dart';
import '../../features/events/presentation/screens/event_attendees_screen.dart';
import '../../features/gdg_events/presentation/screens/gdg_chapters_screen.dart';
import '../../features/gdg_events/presentation/screens/gdg_event_detail_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/qr_checkin_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import '../../features/partnerships/presentation/screens/partner_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/app_shell_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/verification/presentation/screens/verification_requests_screen.dart';
import '../../features/verification/presentation/screens/verification_screen.dart';

const _authRoutes = {'/login', '/register', '/forgot-password'};

/// Screens that only a chapter officer may open. The database enforces this
/// too; the guard just keeps other roles from landing on a dead screen.
bool _isOfficerRoute(String path) =>
    path == '/gdg-chapters' ||
    path == '/verification-requests' ||
    path == '/application-claims' ||
    RegExp(r'^/events/[^/]+/(check-in|attendees)$').hasMatch(path);

/// Single source of truth for navigation. Redirect logic below implements
/// role-agnostic session gating (splash while resolving, auth flow when
/// signed out, shell when signed in); role-*specific* navigation (which
/// bottom-nav tabs / dashboard widgets appear) is handled inside
/// [AppShellScreen] once a user is present, since both roles share the
/// exact same top-level route tree.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);
  final isRecovery = ref.watch(isPasswordRecoveryProvider);

  // Initialize auth side-effect listeners once.
  ref.watch(passwordRecoveryListenerProvider);
  ref.watch(googleTokenListenerProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final matched = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(matched);
      final isSplash = matched == '/splash';
      final isResetRoute = matched == '/reset-password';

      if (authState.isLoading || authState.hasError) {
        return isSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;

      if (user == null) {
        if (isResetRoute) return '/login';
        return isAuthRoute ? null : '/login';
      }

      // Recovery session: force user to /reset-password to set a new password.
      if (isRecovery && !isResetRoute) return '/reset-password';
      if (isResetRoute && !isRecovery) return '/';

      if (isAuthRoute || isSplash) return '/';

      if (_isOfficerRoute(matched) && user.role != UserRole.officer) return '/';
      if (matched.startsWith('/admin') && user.role != UserRole.admin) return '/';
      if (matched == '/audit-log' && user.role == UserRole.member) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(path: '/', builder: (context, state) => const AppShellScreen()),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/check-in',
        builder: (context, state) => QrCheckInScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/attendees',
        builder: (context, state) => EventAttendeesScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/opportunities/:id',
        builder: (context, state) => OpportunityDetailScreen(opportunityId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/partners/:id',
        builder: (context, state) => PartnerDetailScreen(partnerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/gdg-events/:id',
        builder: (context, state) => GdgEventDetailScreen(eventId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/chapters', builder: (context, state) => const AdminChaptersScreen()),
      GoRoute(path: '/admin/members', builder: (context, state) => const AdminMembersScreen()),
      GoRoute(path: '/audit-log', builder: (context, state) => const AuditLogScreen()),
      GoRoute(path: '/gdg-chapters', builder: (context, state) => const GdgChaptersScreen()),
      GoRoute(path: '/application-claims', builder: (context, state) => const ApplicationClaimsScreen()),
      GoRoute(path: '/verify', builder: (context, state) => const VerificationScreen()),
      GoRoute(
        path: '/verification-requests',
        builder: (context, state) => const VerificationRequestsScreen(),
      ),
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/my-calendar', builder: (context, state) => const MyCalendarScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
