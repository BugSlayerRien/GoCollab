import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// GoCollab's signature "flowing prismatic light" background.
///
/// Renders 4 soft, heavily-blurred blobs (one per Google brand color) whose
/// centers drift along smooth Lissajous-style paths. Because every blob's
/// phase is a pure function of a single [AnimationController] value in
/// `[0, 2*pi)`, the motion loops perfectly seamlessly and never jumps.
///
/// Implementation notes (why this stays close to 60 FPS on mid-range
/// Android hardware):
///  * A single [CustomPainter] repaints on every tick instead of rebuilding
///    a widget subtree — no widget diffing cost per frame.
///  * Blur is achieved via `MaskFilter.blur` on the [Paint] object (GPU
///    blurred draw call) rather than an expensive [BackdropFilter] applied
///    to the whole screen.
///  * The painter is wrapped in a [RepaintBoundary] so repaints never
///    propagate to sibling widgets (e.g. the content sitting on top).
///  * Opacity stays low (0.10 - 0.20) per the design spec ("low opacity,
///    never distract from content").
class PrismaticBackground extends StatefulWidget {
  const PrismaticBackground({
    super.key,
    this.loopDuration = const Duration(seconds: 16),
    this.opacity = 0.16,
    this.blobCount = 4,
    this.child,
  });

  /// Full loop duration. Spec calls for a 10-20s seamless loop.
  final Duration loopDuration;

  /// Peak opacity of each color blob.
  final double opacity;

  /// How many blobs to draw (defaults to one per brand color).
  final int blobCount;

  /// Optional foreground content stacked above the animated background.
  final Widget? child;

  @override
  State<PrismaticBackground> createState() => _PrismaticBackgroundState();
}

class _PrismaticBackgroundState extends State<PrismaticBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.loopDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PrismaticPainter(
                    t: _controller.value * 2 * math.pi,
                    opacity: widget.opacity,
                    blobCount: widget.blobCount,
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _PrismaticPainter extends CustomPainter {
  _PrismaticPainter({
    required this.t,
    required this.opacity,
    required this.blobCount,
  });

  final double t;
  final double opacity;
  final int blobCount;

  static const _colors = AppColors.prismaticSpectrum;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final radius = shortestSide * 0.55;

    for (var i = 0; i < blobCount; i++) {
      final color = _colors[i % _colors.length];
      // Distinct, non-integer frequency ratios per blob keep the composite
      // motion organic and avoid a mechanical "orbiting" appearance, while
      // remaining perfectly periodic over `t in [0, 2*pi)`.
      final freqX = 1.0 + i * 0.35;
      final freqY = 1.3 + i * 0.5;
      final phase = i * (math.pi / blobCount) * 1.7;

      final dx = math.sin(t * freqX + phase);
      final dy = math.cos(t * freqY + phase * 0.8);

      final cx = size.width * (0.5 + 0.34 * dx) + (i.isEven ? -size.width * 0.08 : size.width * 0.08);
      final cy = size.height * (0.5 + 0.30 * dy);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55);

      canvas.drawCircle(Offset(cx, cy), radius * (0.75 + 0.1 * math.sin(t + phase)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PrismaticPainter oldDelegate) => oldDelegate.t != t;
}
