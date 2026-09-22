import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/landing_theme.dart';
import 'landing_shared.dart';

class LandingHowItWorks extends StatelessWidget {
  const LandingHowItWorks({required this.compact, super.key});
  
  final bool compact;

  static const _steps = [
    ('01', Icons.calendar_month_rounded, 'Set your event window', 'Pick the date and time first. Every equipment card updates live to that exact slot — no stale numbers.'),
    ('02', Icons.add_shopping_cart_rounded, 'Build your equipment list', 'Browse Sound, Lighting, Visuals and Furniture like a well-organised menu. Tap ADD, adjust quantities.'),
    ('03', Icons.verified_rounded, 'Pay and relax', 'We run a final live warehouse check on checkout. Dispatch approves only when every unit can be fulfilled.'),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = _steps.map((s) => _StepCard(number: s.$1, icon: s.$2, title: s.$3, body: s.$4)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowTitle(eyebrow: 'A BETTER WAY TO RENT',
            title: 'Pick gear the way\nyou build a great menu.',
            body: 'A clear catalogue, live availability, and a clean booking flow — from browse to confirmed in minutes.',
            compact: compact),
        const SizedBox(height: 36),
        compact
            ? Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 14), child: c)).toList())
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: cards[0]), const SizedBox(width: 14),
                Expanded(child: cards[1]), const SizedBox(width: 14),
                Expanded(child: cards[2]),
              ]),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.icon, required this.title, required this.body});
  final String number, title, body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: LandingTheme.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: LandingTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(number, style: GoogleFonts.spaceGrotesk(color: LandingTheme.accent, fontSize: 13, fontWeight: FontWeight.w800)),
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: LandingTheme.surface, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: LandingTheme.ink)),
          ]),
          const SizedBox(height: 24),
          Text(title, style: LandingTheme.heading(size: 20, color: LandingTheme.ink)),
          const SizedBox(height: 10),
          Text(body, style: LandingTheme.label()),
        ]),
      );
}
