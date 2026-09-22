import 'package:flutter/material.dart';
import '../theme/landing_theme.dart';
import 'landing_shared.dart';

class LandingCtaBanner extends StatelessWidget {
  const LandingCtaBanner({required this.onStart, required this.compact, super.key});
  
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 30 : 52),
      decoration: BoxDecoration(color: LandingTheme.accent, borderRadius: BorderRadius.circular(32)),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_copy(), const SizedBox(height: 24), _btn()])
          : Row(children: [Expanded(child: _copy()), const SizedBox(width: 40), _btn()]),
    );
  }

  Widget _copy() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your warehouse\nshouldn\'t need a group chat.', style: LandingTheme.heading(size: 36, color: LandingTheme.ink)),
        const SizedBox(height: 12),
        Text('Start building a clean, conflict-aware event list right now.',
            style: LandingTheme.label(color: LandingTheme.ink.withValues(alpha: 0.72), weight: FontWeight.w600)),
      ]);

  Widget _btn() => PrimaryButton(label: 'Start booking', onTap: onStart, bg: LandingTheme.ink, fg: LandingTheme.white, filled: true);
}
