import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/landing_theme.dart';
import 'landing_shared.dart';

class LandingTestimonials extends StatelessWidget {
  const LandingTestimonials({required this.compact, super.key});
  
  final bool compact;

  static const _quotes = [
    ('Priya Nair', 'Event Director, Luminary Events',
        '"GearGrid eliminated the nightmare of calling the warehouse three times to confirm availability. Our team books in minutes now."',
        'PN', Color(0xFFD4E8FF)),
    ('Arjun Mehta', 'Production Lead, The Collective',
        '"The live availability check caught a double-booking before it happened. Saved our entire product launch."',
        'AM', Color(0xFFD1F5E8)),
    ('Shreya Kapoor', 'Founder, Stagecraft Studios',
        '"The design is something else. Feels like the Apple Store — but for event gear. Our clients love the clean flow."',
        'SK', Color(0xFFFFE8E0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowTitle(eyebrow: 'WHAT CLIENTS SAY',
            title: 'Built for people\nwho run the show.',
            body: 'Event directors and production teams rely on GearGrid to keep their warehouse conflict-free.',
            compact: compact),
        const SizedBox(height: 32),
        if (compact)
          Column(children: _quotes.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TestimonialCard(name: q.$1, role: q.$2, quote: q.$3, initials: q.$4, avatarBg: q.$5))).toList())
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _TestimonialCard(name: _quotes[0].$1, role: _quotes[0].$2, quote: _quotes[0].$3, initials: _quotes[0].$4, avatarBg: _quotes[0].$5)),
            const SizedBox(width: 14),
            Expanded(child: _TestimonialCard(name: _quotes[1].$1, role: _quotes[1].$2, quote: _quotes[1].$3, initials: _quotes[1].$4, avatarBg: _quotes[1].$5)),
            const SizedBox(width: 14),
            Expanded(child: _TestimonialCard(name: _quotes[2].$1, role: _quotes[2].$2, quote: _quotes[2].$3, initials: _quotes[2].$4, avatarBg: _quotes[2].$5)),
          ]),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.name, required this.role, required this.quote,
      required this.initials, required this.avatarBg});
  final String name, role, quote, initials;
  final Color avatarBg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: LandingTheme.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: LandingTheme.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB020)))),
          const SizedBox(height: 16),
          Text(quote, style: LandingTheme.label(color: LandingTheme.ink.withValues(alpha: 0.82), size: 14, weight: FontWeight.w500),
              maxLines: 5, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: avatarBg, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(initials, style: GoogleFonts.spaceGrotesk(
                    color: LandingTheme.ink, fontWeight: FontWeight.w700, fontSize: 13)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.spaceGrotesk(color: LandingTheme.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(role, style: LandingTheme.label(size: 11, weight: FontWeight.w500)),
            ]),
          ]),
        ]),
      );
}
