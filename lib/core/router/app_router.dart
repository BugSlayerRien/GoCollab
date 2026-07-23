import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/qr_checkin_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import '../../features/partnerships/presentation/screens/partner_detail_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/shell/presentation/screens/app_shell_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

const _authRoutes = {'/login', '/register', '/forgot-password'};

/// Single source of truth for navigation. Redirect logic below implements
/// role-agnostic session gating (splash while resolving, auth flow when
/// signed out, shell when signed in); role-*specific* navigation (which
/// bottom-nav tabs / dashboard widgets appear) is handled inside
/// [AppShellScreen] once a user is present, since both roles share the
/// exact same top-level route tree.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final matched = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(matched);
      final isSplash = matched == '/splash';

      if (authState.isLoading || authState.hasError) {
        return isSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute || isSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
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
        path: '/opportunities/:id',
        builder: (context, state) => OpportunityDetailScreen(opportunityId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/partners/:id',
        builder: (context, state) => PartnerDetailScreen(partnerId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile/edit', builder: (context, state) => const EditProfileScreen()),
    ],
  );
});
