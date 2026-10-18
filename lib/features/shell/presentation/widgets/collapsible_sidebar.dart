import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/gocollab_logo.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/shell_providers.dart';
import 'prismatic_nav_bar.dart';

/// Burger button for the app bar of every officer/admin tab. Members use the
/// bottom bar, so for them this renders nothing.
Widget? sidebarMenuLeading(WidgetRef ref) {
  final role = ref.watch(currentUserProvider).valueOrNull?.role;
  if (role == null || role == UserRole.member) return null;
  return const SidebarMenuButton();
}

class SidebarMenuButton extends ConsumerWidget {
  const SidebarMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => ref.read(sidebarOpenProvider.notifier).state = true,
    );
  }
}

/// Navigation for officers and admins, who have more destinations than a
/// bottom bar can hold. The menu is completely hidden (the page keeps its full
/// width) until the burger button is pressed; it then slides in over a dimmed
/// scrim. Choosing a destination, tapping the scrim, or swiping it away
/// closes it again.
class CollapsibleSidebar extends ConsumerStatefulWidget {
  const CollapsibleSidebar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<NavDestinationSpec> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  ConsumerState<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends ConsumerState<CollapsibleSidebar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  @override
  void initState() {
    super.initState();
    // the provider is the single source of truth; the controller only animates it
    ref.listenManual<bool>(sidebarOpenProvider, (previous, open) {
      if (open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => ref.read(sidebarOpenProvider.notifier).state = false;

  void _select(int index) {
    widget.onDestinationSelected(index);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.8).clamp(220.0, 300.0);
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, _) => IgnorePointer(
              ignoring: _curve.value == 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.4 * _curve.value)),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _curve,
          builder: (context, child) => Positioned(
            left: -width * (1 - _curve.value),
            top: 0,
            bottom: 0,
            width: width,
            child: child!,
          ),
          child: GestureDetector(
            // swipe left to dismiss
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -200) _close();
            },
            child: Material(
              color: context.appSurface,
              elevation: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border(right: BorderSide(color: context.appBorder))),
                child: SafeArea(
                  right: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onClose: _close),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          itemCount: widget.destinations.length,
                          itemBuilder: (context, i) => _Item(
                            spec: widget.destinations[i],
                            selected: i == widget.selectedIndex,
                            onTap: () => _select(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          const GoCollabLogo(size: 36, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'GoCollab',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(tooltip: 'Close menu', icon: const Icon(Icons.close_rounded), onPressed: onClose),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.spec, required this.selected, required this.onTap});

  final NavDestinationSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.googleBlue : context.appTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.googleBlue.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(selected ? spec.selectedIcon : spec.icon, color: color, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      spec.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
