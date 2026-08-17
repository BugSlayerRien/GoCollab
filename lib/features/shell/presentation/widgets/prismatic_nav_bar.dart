import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';

class NavDestinationSpec {
  const NavDestinationSpec({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Custom bottom navigation bar whose *selected item indicator* is a slow,
/// looping prismatic gradient pill — one of the design spec's explicitly
/// sanctioned placements for the animated brand identity ("Selected
/// navigation indicator"). Built with [AnimationController] + [LinearGradient],
/// no image/Lottie assets.
class PrismaticNavBar extends StatefulWidget {
  const PrismaticNavBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final List<NavDestinationSpec> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<PrismaticNavBar> createState() => _PrismaticNavBarState();
}

class _PrismaticNavBarState extends State<PrismaticNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(widget.destinations.length, (index) {
              final destination = widget.destinations[index];
              final isSelected = index == widget.selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => widget.onDestinationSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 34,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isSelected)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: 44,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                        gradient: LinearGradient(
                                          colors: AppColors.prismaticSpectrum,
                                          begin: Alignment(-1 + _controller.value * 2, 0),
                                          end: Alignment(1 + _controller.value * 2, 0),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.googleBlue.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Icon(
                                    isSelected ? destination.selectedIcon : destination.icon,
                                    color: isSelected ? Colors.white : context.appTextDisabled,
                                    size: 22,
                                    shadows: isSelected
                                        ? const [Shadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1))]
                                        : null,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.googleBlue : context.appTextDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
