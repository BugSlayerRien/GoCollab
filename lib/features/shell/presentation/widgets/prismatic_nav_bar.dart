import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
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
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: AppColors.prismaticSpectrum,
                                      begin: Alignment(-1 + _controller.value * 2, 0),
                                      end: Alignment(1 + _controller.value * 2, 0),
                                      transform: const GradientRotation(0.4),
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                            ),
                            child: Icon(
                              isSelected ? destination.selectedIcon : destination.icon,
                              color: isSelected ? Colors.white : AppColors.textDisabled,
                              size: 22,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destination.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.googleBlue : AppColors.textDisabled,
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
