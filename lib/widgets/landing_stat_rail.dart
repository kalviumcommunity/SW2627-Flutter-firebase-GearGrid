import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/landing_theme.dart';

class LandingStatRail extends StatelessWidget {
  const LandingStatRail({required this.compact, super.key});
  
  final bool compact;

  TextStyle get _numStyle => GoogleFonts.spaceGrotesk(
      color: LandingTheme.lime, fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 32, horizontal: compact ? 24 : 44),
      decoration: BoxDecoration(color: LandingTheme.ink, borderRadius: BorderRadius.circular(26)),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Stat(label: 'Bookings powered', child: _CountUpText(target: 2400, prefix: '', suffix: '+', style: _numStyle)),
              _hDivider(),
              _Stat(label: 'Double bookings ever', child: Text('Zero', style: _numStyle)),
              _hDivider(),
              _Stat(label: 'Avg approval time', child: Text('< 2 min', style: _numStyle)),
            ])
          : Row(children: [
              Expanded(child: _Stat(label: 'Bookings powered', child: _CountUpText(target: 2400, prefix: '', suffix: '+', style: _numStyle))),
              _vDivider(),
              Expanded(child: _Stat(label: 'Double bookings ever', child: Text('Zero', style: _numStyle))),
              _vDivider(),
              Expanded(child: _Stat(label: 'Avg approval time', child: Text('< 2 min', style: _numStyle))),
            ]),
    );
  }

  Widget _hDivider() => Padding(padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.08)));

  Widget _vDivider() => Container(width: 1, height: 60,
      color: Colors.white.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.child, required this.label});
  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          child,
          const SizedBox(height: 4),
          Text(label, style: LandingTheme.label(color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w600)),
        ]),
      );
}

class _CountUpText extends StatefulWidget {
  const _CountUpText({required this.target, required this.prefix, required this.suffix, required this.style});
  final int target;
  final String prefix, suffix;
  final TextStyle style;
  @override
  State<_CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<_CountUpText> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }
  
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Text('${widget.prefix}${(_anim.value * widget.target).round()}${widget.suffix}', style: widget.style),
  );
}
