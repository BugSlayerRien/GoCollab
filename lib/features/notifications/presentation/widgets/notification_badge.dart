import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bell icon button with a small pulsing red badge when [unreadCount] > 0 —
/// the "notification badge pulses" microinteraction called out in the spec.
/// Built with a plain [AnimationController] (no Lottie/GIF), gently scaling
/// and fading a soft outer ring behind a solid count dot so the pulse reads
/// as "new activity" without being distracting.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key, required this.unreadCount, required this.onPressed});

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: widget.onPressed,
          icon: Icon(hasUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded),
        ),
        if (hasUnread)
          Positioned(
            top: 4,
            right: 4,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final t = _pulseController.value;
                  return SizedBox(
                    width: 20,
                    height: 20,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Slow-expanding, fading ring behind the solid dot.
                        Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0) * 0.6,
                          child: Container(
                            width: 12 + (t * 10),
                            height: 12 + (t * 10),
                            decoration: const BoxDecoration(color: AppColors.googleRed, shape: BoxShape.circle),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.googleRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
                          ),
                          child: widget.unreadCount > 9
                              ? null
                              : Text(
                                  '${widget.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
