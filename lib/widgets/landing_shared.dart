import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/landing_theme.dart';

class EyebrowTitle extends StatelessWidget {
  const EyebrowTitle({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.compact,
    super.key,
  });
  
  final String eyebrow, title, body;
  final bool compact;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow, style: GoogleFonts.spaceGrotesk(
              color: LandingTheme.accent, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text(title, style: LandingTheme.heading(size: compact ? 36 : 48, color: LandingTheme.ink)),
          const SizedBox(height: 16),
          Text(body, style: LandingTheme.label(size: 15, weight: FontWeight.w500)),
        ]),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.icon, required this.label, super.key});
  
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF1E3226), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: LandingTheme.lime),
          const SizedBox(width: 7),
          Text(label, style: GoogleFonts.spaceGrotesk(
              color: LandingTheme.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.9)),
        ]),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
    this.mini = false,
    this.bg = LandingTheme.accent,
    this.fg = LandingTheme.ink,
    super.key,
  });
  
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled, mini;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(horizontal: mini ? 18 : 22, vertical: mini ? 13 : 17);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: mini ? 13 : 15)),
        style: FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg, padding: padding, shape: shape),
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(backgroundColor: filled ? bg : LandingTheme.ink,
          foregroundColor: filled ? fg : Colors.white, padding: padding, shape: shape),
      child: Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: mini ? 13 : 15)),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({required this.dark, this.small = false, super.key});
  
  final bool dark;
  final bool small;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 30 : 40, height: small ? 30 : 40,
            decoration: BoxDecoration(color: LandingTheme.accent, borderRadius: BorderRadius.circular(small ? 9 : 13)),
            child: Icon(Icons.graphic_eq_rounded, size: small ? 18 : 24, color: dark ? LandingTheme.ink : LandingTheme.white),
          ),
          const SizedBox(width: 10),
          Text('GearGrid', style: GoogleFonts.spaceGrotesk(
              color: dark ? LandingTheme.ink : LandingTheme.white, fontWeight: FontWeight.w700,
              fontSize: small ? 18 : 22, letterSpacing: -0.8)),
        ],
      );
}
