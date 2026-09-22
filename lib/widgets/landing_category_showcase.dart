import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/landing_theme.dart';
import 'landing_shared.dart';
import 'landing_utils.dart';

class LandingCategoryShowcase extends StatelessWidget {
  const LandingCategoryShowcase({
    required this.compact,
    required this.onStart,
    required this.categories,
    required this.equipment,
    super.key,
  });
  
  final bool compact;
  final VoidCallback onStart;
  final List<String> categories;
  final List<Equipment> equipment;

  int _countFor(String cat) => equipment.where((e) => e.category == cat).length;

  @override
  Widget build(BuildContext context) {
    final cats = categories.isNotEmpty ? categories : ['Sound', 'Lighting', 'Visuals', 'Furniture'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowTitle(eyebrow: 'EQUIPMENT CATALOGUE',
            title: 'Everything for\nyour stage.',
            body: 'From wireless microphones to LED stages, every category is live-checked against your event date.',
            compact: compact),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFFECEAE2), borderRadius: BorderRadius.circular(32)),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compact ? 2 : 4, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: compact ? 1.0 : 0.9,
            ),
            itemBuilder: (context, i) {
              final cat = cats[i];
              final palette = LandingUtils.catBgPalette[i % LandingUtils.catBgPalette.length];
              final count = _countFor(cat);
              return _CategoryCard(label: cat, icon: LandingUtils.catIcon(cat),
                  bg: palette.$2, fg: palette.$1, count: count, onTap: onStart);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.label, required this.icon, required this.bg,
      required this.fg, required this.count, required this.onTap});
  final String label;
  final IconData icon;
  final Color bg, fg;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: fg, size: 32),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                  child: Text('$count items', style: GoogleFonts.manrope(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ]),
            const Spacer(),
            Text(label, style: GoogleFonts.spaceGrotesk(color: fg, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Text('Browse collection', style: LandingTheme.label(color: fg.withValues(alpha: 0.6), size: 11, weight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: fg.withValues(alpha: 0.6)),
            ]),
          ]),
        ),
      );
}
