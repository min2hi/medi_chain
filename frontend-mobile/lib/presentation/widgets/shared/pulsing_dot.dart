import 'package:flutter/material.dart';

/// PulsingDot — A status dot indicating live activity or urgent status.
/// Animates a glowing halo expanding and fading around a solid core.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 6.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
        return SizedBox(
          width: widget.size * 2.5,
          height: widget.size * 2.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing outer halo
              Container(
                width: widget.size * 2.5 * _controller.value,
                height: widget.size * 2.5 * _controller.value,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.4 * (1.0 - _controller.value)),
                  shape: BoxShape.circle,
                ),
              ),
              // Solid core dot
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
