import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Wraps [child] (typically a featured event/opportunity card) with a
/// slowly-rotating prismatic gradient border — a subtle, premium "featured"
/// treatment built with [AnimationController] + [SweepGradient], no assets.
class PrismaticGlowBorder extends StatefulWidget {
  const PrismaticGlowBorder({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusLg,
    this.borderWidth = 2.2,
    this.duration = const Duration(seconds: 12),
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Duration duration;

  @override
  State<PrismaticGlowBorder> createState() => _PrismaticGlowBorderState();
}

class _PrismaticGlowBorderState extends State<PrismaticGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _GlowBorderPainter(
            progress: _controller.value,
            radius: widget.borderRadius,
            strokeWidth: widget.borderWidth,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({required this.progress, required this.radius, required this.strokeWidth});

  final double progress;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + 2 * math.pi,
      colors: const [
        ...AppColors.prismaticSpectrum,
        AppColors.googleBlue, // seam blend for a seamless loop
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) => oldDelegate.progress != progress;
}
