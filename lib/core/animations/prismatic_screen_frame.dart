import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Thin animated prismatic accents along the left/right screen edges — the
/// "premium frame" visible on Career Hub and other main tabs in the design.
class PrismaticScreenFrame extends StatefulWidget {
  const PrismaticScreenFrame({super.key, required this.child, this.edgeWidth = 3.5});

  final Widget child;
  final double edgeWidth;

  @override
  State<PrismaticScreenFrame> createState() => _PrismaticScreenFrameState();
}

class _PrismaticScreenFrameState extends State<PrismaticScreenFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = _controller.value * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            child!,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: widget.edgeWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.googleRed.withValues(alpha: 0.85),
                        AppColors.googleYellow.withValues(alpha: 0.85),
                        AppColors.googleGreen.withValues(alpha: 0.85),
                        AppColors.googleBlue.withValues(alpha: 0.85),
                      ],
                      transform: GradientRotation(shift),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: widget.edgeWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.googleBlue.withValues(alpha: 0.85),
                        AppColors.googleGreen.withValues(alpha: 0.85),
                        AppColors.googleYellow.withValues(alpha: 0.85),
                        AppColors.googleRed.withValues(alpha: 0.85),
                      ],
                      transform: GradientRotation(-shift),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
