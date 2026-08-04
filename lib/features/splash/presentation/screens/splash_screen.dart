import 'package:flutter/material.dart';
import '../../../../core/animations/prismatic_background.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/gocollab_logo.dart';

/// The Flutter-rendered splash shown immediately after the native launch
/// screen while Supabase session restoration / role resolution happens in
/// the background (see `AppRouter`'s redirect logic). Uses the prismatic
/// background at a slightly higher opacity since there is no other content
/// competing for attention here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: PrismaticBackground(
        opacity: 0.2,
        loopDuration: const Duration(seconds: 14),
        child: Center(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: const GoCollabLogo(size: 96, showShadow: true),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('GoCollab', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'GDGoC Philippines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
