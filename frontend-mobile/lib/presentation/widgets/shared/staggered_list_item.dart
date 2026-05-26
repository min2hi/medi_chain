import 'package:flutter/material.dart';

/// Shared staggered entrance animation for list items.
///
/// Wraps any widget with a subtle fade + slide-up reveal.
/// Used across Patient, Doctor, Admin portals for consistent list UX.
///
/// Usage:
/// ```dart
/// itemBuilder: (_, i) => StaggeredListItem(
///   index: i,
///   child: YourCard(...),
/// )
/// ```
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;

  /// Delay multiplier in ms per index step (default: 55ms, capped at 280ms)
  final int delayPerIndex;

  /// Total animation duration (default: 370ms)
  final int durationMs;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.delayPerIndex = 55,
    this.durationMs = 370,
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delay = Duration(
      milliseconds: (widget.index * widget.delayPerIndex).clamp(0, 280),
    );
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
