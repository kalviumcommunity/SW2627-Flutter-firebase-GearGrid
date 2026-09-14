import 'package:flutter/material.dart';

/// An animated pulsing availability dot.
/// - Green when [available] > 3
/// - Amber when [available] is 1-3 (low stock)
/// - Red when [available] == 0 (unavailable)
class LivePulseDot extends StatefulWidget {
  const LivePulseDot({required this.available, this.size = 8, super.key});

  final int available;
  final double size;

  @override
  State<LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<LivePulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);

    _scale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.available == 0) return const Color(0xFFE53935);
    if (widget.available <= 3) return const Color(0xFFFB8C00);
    return const Color(0xFF00C853);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple ring
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Core dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Compact availability label row (dot + text).
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({required this.available, super.key});

  final int available;

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final String label;

    if (available == 0) {
      textColor = const Color(0xFFE53935);
      label = 'Unavailable';
    } else if (available <= 3) {
      textColor = const Color(0xFFFB8C00);
      label = 'Only $available left';
    } else {
      textColor = const Color(0xFF00C853);
      label = '$available available';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LivePulseDot(available: available, size: 6),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
