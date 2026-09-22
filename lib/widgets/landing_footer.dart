import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/landing_theme.dart';
import 'landing_shared.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({required this.compact, super.key});
  
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const BrandLockup(dark: true, small: true),
      const Spacer(),
      if (!compact)
        Text('LIVE INVENTORY FOR LIVE EVENTS', style: GoogleFonts.spaceGrotesk(
            color: LandingTheme.ink.withValues(alpha: 0.35), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
    ]);
  }
}
