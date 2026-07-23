import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Google-branded "Sign in with Google" button following Google's own
/// identity guidelines (white background, colored "G" mark, gray border).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleGlyph(),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
      ),
    );
  }
}

/// A lightweight, dependency-free rendering of the Google "G" mark using
/// four colored arcs — avoids bundling an image asset for a single icon.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 3.2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Four quarter-arcs approximating the "G" mark colors.
    paint.color = AppColors.googleRed;
    canvas.drawArc(rect.deflate(strokeWidth / 2), -1.55, 1.55, false, paint);
    paint.color = AppColors.googleYellow;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 1.6, false, paint);
    paint.color = AppColors.googleGreen;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 1.6, 1.55, false, paint);
    paint.color = AppColors.googleBlue;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 3.15, 1.6, false, paint);

    // Horizontal bar of the G.
    final barPaint = Paint()..color = AppColors.googleBlue;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.52, size.height * 0.44, size.width * 0.42, size.height * 0.14),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
