import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A loading-skeleton "shimmer" built natively with [ShaderMask] +
/// [AnimationController] — no Lottie/GIF assets. A soft prismatic gradient
/// sweeps left-to-right across a light-gray block, evoking the brand's
/// flowing-light identity even in loading states.
class PrismaticShimmer extends StatefulWidget {
  const PrismaticShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  final double? width;
  final double height;
  final double borderRadius;

  /// Convenience constructor for a rectangular media/image placeholder.
  const PrismaticShimmer.block({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppSpacing.radiusMd,
  });

  @override
  State<PrismaticShimmer> createState() => _PrismaticShimmerState();
}

class _PrismaticShimmerState extends State<PrismaticShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value * 2.6 - 0.8;
            return LinearGradient(
              begin: Alignment(-1.5 + sweep, 0),
              end: Alignment(0.5 + sweep, 0),
              colors: const [
                AppColors.surfaceLightGray,
                AppColors.googleBlue,
                AppColors.googleGreen,
                AppColors.googleYellow,
                AppColors.surfaceLightGray,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.surfaceLightGray,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// A ready-made skeleton line-group for card placeholders (e.g. announcement
/// or opportunity cards while the network request is in-flight).
class PrismaticSkeletonCard extends StatelessWidget {
  const PrismaticSkeletonCard({super.key, this.height = 140});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrismaticShimmer.block(height: height * 0.45, width: double.infinity),
          const SizedBox(height: AppSpacing.sm),
          const PrismaticShimmer(width: double.infinity, height: 14),
          const SizedBox(height: AppSpacing.xs),
          const PrismaticShimmer(width: 160, height: 14),
        ],
      ),
    );
  }
}
