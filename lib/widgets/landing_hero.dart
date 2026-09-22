import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/landing_theme.dart';
import 'landing_shared.dart';
import 'landing_utils.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({
    required this.onStart,
    required this.compact,
    required this.heroFade,
    required this.floatingCards,
    required this.equipment,
    required this.totalUnits,
    super.key,
  });
  
  final VoidCallback onStart;
  final bool compact;
  final AnimationController heroFade, floatingCards;
  final List<Equipment> equipment;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    final copyCol = _CopyColumn(onStart: onStart, compact: compact);
    final visual = _HeroVisual(
        floatingCards: floatingCards,
        compact: compact,
        equipment: equipment,
        totalUnits: totalUnits);
        
    return FadeTransition(
      opacity: CurvedAnimation(parent: heroFade, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: heroFade, curve: Curves.easeOutCubic)),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: BoxConstraints(minHeight: compact ? 600 : 680),
          padding: EdgeInsets.all(compact ? 28 : 52),
          decoration: BoxDecoration(color: LandingTheme.ink, borderRadius: BorderRadius.circular(36)),
          child: compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  copyCol, const SizedBox(height: 44), SizedBox(height: 340, child: visual),
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 5, child: copyCol),
                  const SizedBox(width: 36),
                  Expanded(flex: 6, child: SizedBox(height: 520, child: visual)),
                ]),
        ),
      ),
    );
  }
}

class _CopyColumn extends StatelessWidget {
  const _CopyColumn({required this.onStart, required this.compact});
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusPill(icon: Icons.bolt_rounded, label: 'LIVE INVENTORY · ZERO SURPRISES'),
        const SizedBox(height: 28),
        Text('Great events\nstart with a\nclean cart.', style: LandingTheme.display(size: compact ? 52 : 72)),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'A premium equipment rental flow for sound, light, screens, furniture, and every moment in between. Real-time availability. Zero double bookings.',
            style: LandingTheme.label(color: const Color(0xFFB0BDB0), size: 15, weight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 36),
        PrimaryButton(
          label: 'Build your equipment list',
          onTap: onStart,
          icon: Icons.arrow_forward_rounded,
          filled: true,
          bg: LandingTheme.lime,
          fg: LandingTheme.ink,
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({
    required this.floatingCards,
    required this.compact,
    required this.equipment,
    required this.totalUnits,
  });
  
  final AnimationController floatingCards;
  final bool compact;
  final List<Equipment> equipment;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    final cats = <(String, IconData, Color)>[];
    final seen = <String>{};
    for (final e in equipment) {
      if (!seen.add(e.category)) continue;
      final idx = seen.length - 1;
      cats.add((e.category, LandingUtils.catIcon(e.category), LandingUtils.catBgPalette[idx % LandingUtils.catBgPalette.length].$1));
      if (cats.length == 4) break;
    }
    while (cats.length < 4) {
      const fallbacks = [
        ('Sound', Icons.speaker_group_rounded),
        ('Lighting', Icons.lightbulb_outline_rounded),
        ('Visuals', Icons.tv_rounded),
        ('Furniture', Icons.weekend_outlined),
      ];
      final idx = cats.length;
      cats.add((fallbacks[idx].$1, fallbacks[idx].$2, LandingUtils.catBgPalette[idx % LandingUtils.catBgPalette.length].$1));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: LandingTheme.cardDark, borderRadius: BorderRadius.circular(28)),
            child: Center(child: Icon(Icons.grid_view_rounded,
                color: Colors.white.withValues(alpha: 0.04), size: 220)),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: cats.map((c) => _HeroTile(label: c.$1, icon: c.$2, color: c.$3)).toList(),
            ),
          ),
        ),
        Positioned(
          top: 18, right: 18,
          child: AnimatedBuilder(
            animation: floatingCards,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -4 * math.sin(floatingCards.value * math.pi)), child: child),
            child: _FloatingAvailabilityCard(totalUnits: totalUnits),
          ),
        ),
        Positioned(
          bottom: 18, left: 18,
          child: AnimatedBuilder(
            animation: floatingCards,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, 4 * math.sin(floatingCards.value * math.pi)), child: child),
            child: const _FloatingOrderCard(),
          ),
        ),
      ],
    );
  }
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 28),
            const Spacer(),
            Text(label, style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Browse →', style: GoogleFonts.manrope(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _FloatingAvailabilityCard extends StatelessWidget {
  const _FloatingAvailabilityCard({required this.totalUnits});
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    final label = totalUnits > 0 ? 'Live · $totalUnits units available' : 'Availability · synced live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEEE8F5D6),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.manrope(color: const Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FloatingOrderCard extends StatelessWidget {
  const _FloatingOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: LandingTheme.lime, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shopping_bag_outlined, color: LandingTheme.ink, size: 16),
            ),
            const SizedBox(width: 8),
            Text('SAMPLE BOOKING', style: GoogleFonts.spaceGrotesk(
                fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: LandingTheme.muted)),
          ]),
          const SizedBox(height: 12),
          Text('Sample booking · 12 items', style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, fontSize: 14, color: LandingTheme.ink, height: 1.2)),
          const SizedBox(height: 4),
          Text('Slot confirmed', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 11, color: LandingTheme.muted)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 0.78, color: LandingTheme.accent, backgroundColor: LandingTheme.border, minHeight: 5),
          ),
        ],
      ),
    );
  }
}
