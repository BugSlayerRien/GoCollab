import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A branded circular loading indicator: four arcs (one per brand color)
/// chasing each other around the ring. Built purely with
/// [AnimationController] + [CustomPainter] — used for full-screen loading
/// states in premium areas (splash, dashboard header refresh).
class PrismaticLoader extends StatefulWidget {
  const PrismaticLoader({super.key, this.size = 40, this.strokeWidth = 4});

  final double size;
  final double strokeWidth;

  @override
  State<PrismaticLoader> createState() => _PrismaticLoaderState();
}

class _PrismaticLoaderState extends State<PrismaticLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _LoaderPainter(progress: _controller.value, strokeWidth: widget.strokeWidth),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const colors = AppColors.prismaticSpectrum;
    final arcSweep = (2 * math.pi) / colors.length * 0.7;

    for (var i = 0; i < colors.length; i++) {
      final start = progress * 2 * math.pi + i * (2 * math.pi / colors.length);
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, arcSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) => oldDelegate.progress != progress;
}
