import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medi_chain_mobile/core/theme/app_theme.dart';

/// Card có press animation (scale 0.97) + haptic + accent border khi nhấn.
/// Promoted từ _PressableCard private ở dashboard → dùng chung toàn bộ Admin.
/// Pattern: Linear / Stripe mobile dark card.
class AdminPressableCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AdminPressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.accentColor = AdminColors.aiPrimary,
    this.padding,
    this.borderRadius,
  });

  @override
  State<AdminPressableCard> createState() => _AdminPressableCardState();
}

class _AdminPressableCardState extends State<AdminPressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(14);
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _pressed ? AdminColors.elevated : AdminColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: _pressed
                  ? widget.accentColor.withOpacity(0.45)
                  : AdminColors.border,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
