import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ScaleOnTap — A wrapper widget that scales down its child slightly when pressed,
/// providing modern tactile feedback (incorporating light haptics).
class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownFactor;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownFactor = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.onTap != null;

    return GestureDetector(
      onTapDown: isInteractive
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isInteractive ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDownFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
