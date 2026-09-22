import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/landing_theme.dart';
import 'landing_shared.dart';

class LandingNavBar extends StatelessWidget {
  const LandingNavBar({
    required this.scrolled,
    required this.compact,
    required this.onStart,
    super.key,
  });
  
  final bool scrolled, compact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: scrolled ? LandingTheme.surface.withValues(alpha: 0.94) : LandingTheme.surface.withValues(alpha: 0.0),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56),
          decoration: BoxDecoration(
            border: scrolled ? const Border(bottom: BorderSide(color: Color(0xFFE5E0D5), width: 1)) : null,
          ),
          child: Row(
            children: [
              const BrandLockup(dark: true),
              const Spacer(),
              if (!compact) ...[
                const _NavLink(label: 'How it works'),
                const SizedBox(width: 32),
                const _NavLink(label: 'Equipment'),
                const SizedBox(width: 24),
              ],
              TextButton(
                onPressed: onStart,
                style: TextButton.styleFrom(
                  foregroundColor: LandingTheme.ink,
                  textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                child: const Text('Sign in'),
              ),
              const SizedBox(width: 8),
              PrimaryButton(label: compact ? 'Get started' : 'Start booking', onTap: onStart, mini: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label});
  final String label;
  
  @override
  Widget build(BuildContext context) => Text(label,
      style: LandingTheme.label(color: LandingTheme.ink.withValues(alpha: 0.65), weight: FontWeight.w700));
}
