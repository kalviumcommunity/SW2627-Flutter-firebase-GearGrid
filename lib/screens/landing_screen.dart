import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../services/firestore_repository.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _G {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF6B35);
  static const lime = Color(0xFFC8F135);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);
  static const cardDark = Color(0xFF1A2920);

  static TextStyle display(
          {double size = 64,
          Color color = const Color(0xFFFFFFFF),
          double tracking = -3.0}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: tracking,
          height: 0.95);

  static TextStyle heading(
          {double size = 40, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -1.8,
          height: 1.05);

  static TextStyle label(
          {double size = 13,
          Color color = const Color(0xFF8A9489),
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(
          fontSize: size, fontWeight: weight, color: color, height: 1.55);
}

// ─── Category helpers ─────────────────────────────────────────────────────────

IconData _catIcon(String cat) => switch (cat.toLowerCase()) {
      'sound' || 'audio' => Icons.speaker_group_rounded,
      'lighting' || 'lights' => Icons.lightbulb_outline_rounded,
      'visual' || 'visuals' || 'screen' || 'screens' => Icons.tv_rounded,
      'furniture' => Icons.weekend_outlined,
      'staging' || 'stage' => Icons.theater_comedy_rounded,
      'power' => Icons.bolt_rounded,
      _ => Icons.inventory_2_outlined,
    };

const _catBgPalette = [
  (Color(0xFF1E3A5F), Color(0xFFD4E8FF)),
  (Color(0xFF3D2E0A), Color(0xFFFFF3CC)),
  (Color(0xFF0A3325), Color(0xFFD1F5E8)),
  (Color(0xFF3A1A2E), Color(0xFFFFE8E0)),
  (Color(0xFF1F1A40), Color(0xFFEFE8FF)),
  (Color(0xFF3D2000), Color(0xFFFFEDD5)),
];

// ─── LandingScreen ────────────────────────────────────────────────────────────

class LandingScreen extends StatefulWidget {
  const LandingScreen({required this.onStart, super.key});
  final VoidCallback onStart;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scroll;
  late final AnimationController _heroFade;
  late final AnimationController _floatingCards;
  bool _navScrolled = false;

  final _repo = FirestoreRepository();
  List<Equipment> _equipment = [];

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()
      ..addListener(() {
        final scrolled = _scroll.offset > 60;
        if (scrolled != _navScrolled) setState(() => _navScrolled = scrolled);
      });
    _heroFade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _floatingCards = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _repo.watchEquipment().listen(
      (list) { if (mounted) setState(() => _equipment = list); },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _heroFade.dispose();
    _floatingCards.dispose();
    super.dispose();
  }

  int get _totalUnits => _equipment.fold(0, (s, e) => s + e.totalUnits);

  List<String> get _uniqueCategories {
    final seen = <String>{};
    return _equipment.map((e) => e.category).where(seen.add).take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;

    return Scaffold(
      backgroundColor: _G.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 56, 
                    MediaQuery.paddingOf(context).top + 88, 
                    compact ? 20 : 56, 60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroSection(
                        onStart: widget.onStart,
                        compact: compact,
                        heroFade: _heroFade,
                        floatingCards: _floatingCards,
                        equipment: _equipment,
                        totalUnits: _totalUnits),
                    const SizedBox(height: 32),
                    _StatRail(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    _HowItWorks(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    _CategoryShowcase(
                        compact: compact,
                        onStart: widget.onStart,
                        categories: _uniqueCategories,
                        equipment: _equipment),
                    SizedBox(height: compact ? 64 : 96),
                    _TestimonialsSection(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    _CtaBanner(onStart: widget.onStart, compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    _Footer(compact: compact),
                  ]),
                ),
              )
            ],
          ),
          _NavBar(scrolled: _navScrolled, compact: compact, onStart: widget.onStart),
        ],
      ),
    );
  }
}

// ─── Navbar ───────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.scrolled, required this.compact, required this.onStart});
  final bool scrolled, compact;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: scrolled ? _G.surface.withValues(alpha: 0.94) : _G.surface.withValues(alpha: 0.0),
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
              _BrandLockup(dark: true),
              const Spacer(),
              if (!compact) ...[
                _NavLink(label: 'How it works'),
                const SizedBox(width: 32),
                _NavLink(label: 'Equipment'),
                const SizedBox(width: 24),
              ],
              TextButton(
                onPressed: onStart,
                style: TextButton.styleFrom(
                  foregroundColor: _G.ink,
                  textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                child: const Text('Sign in'),
              ),
              const SizedBox(width: 8),
              _PrimaryButton(label: compact ? 'Get started' : 'Start booking', onTap: onStart, mini: true),
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
      style: _G.label(color: _G.ink.withValues(alpha: 0.65), weight: FontWeight.w700));
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.onStart, required this.compact, required this.heroFade,
    required this.floatingCards, required this.equipment, required this.totalUnits,
  });
  final VoidCallback onStart;
  final bool compact;
  final AnimationController heroFade, floatingCards;
  final List<Equipment> equipment;
  final int totalUnits;

  @override
  Widget build(BuildContext context) {
    final copyCol = _CopyColumn(onStart: onStart, compact: compact);
    final visual = _HeroVisual(floatingCards: floatingCards, compact: compact,
        equipment: equipment, totalUnits: totalUnits);
    return FadeTransition(
      opacity: CurvedAnimation(parent: heroFade, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: heroFade, curve: Curves.easeOutCubic)),
        child: Container(
          clipBehavior: Clip.antiAlias,
          constraints: BoxConstraints(minHeight: compact ? 600 : 680),
          padding: EdgeInsets.all(compact ? 28 : 52),
          decoration: BoxDecoration(color: _G.ink, borderRadius: BorderRadius.circular(36)),
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
        _StatusPill(icon: Icons.bolt_rounded, label: 'LIVE INVENTORY · ZERO SURPRISES'),
        const SizedBox(height: 28),
        Text('Great events\nstart with a\nclean cart.', style: _G.display(size: compact ? 52 : 72)),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'A premium equipment rental flow for sound, light, screens, furniture, and every moment in between. Real-time availability. Zero double bookings.',
            style: _G.label(color: const Color(0xFFB0BDB0), size: 15, weight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 36),
        _PrimaryButton(
          label: 'Build your equipment list',
          onTap: onStart,
          icon: Icons.arrow_forward_rounded,
          filled: true,
          bg: _G.lime,
          fg: _G.ink,
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.floatingCards, required this.compact,
      required this.equipment, required this.totalUnits});
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
      cats.add((e.category, _catIcon(e.category), _catBgPalette[idx % _catBgPalette.length].$1));
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
      cats.add((fallbacks[idx].$1, fallbacks[idx].$2, _catBgPalette[idx % _catBgPalette.length].$1));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: _G.cardDark, borderRadius: BorderRadius.circular(28)),
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
              decoration: BoxDecoration(color: _G.lime, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shopping_bag_outlined, color: _G.ink, size: 16),
            ),
            const SizedBox(width: 8),
            Text('SAMPLE BOOKING', style: GoogleFonts.spaceGrotesk(
                fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: _G.muted)),
          ]),
          const SizedBox(height: 12),
          Text('Sample booking · 12 items', style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700, fontSize: 14, color: _G.ink, height: 1.2)),
          const SizedBox(height: 4),
          Text('Slot confirmed', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 11, color: _G.muted)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: 0.78, color: _G.accent, backgroundColor: _G.border, minHeight: 5),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Rail ───────────────────────────────────────────────────────────────

class _StatRail extends StatelessWidget {
  const _StatRail({required this.compact});
  final bool compact;

  TextStyle get _numStyle => GoogleFonts.spaceGrotesk(
      color: _G.lime, fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 32, horizontal: compact ? 24 : 44),
      decoration: BoxDecoration(color: _G.ink, borderRadius: BorderRadius.circular(26)),
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
          Text(label, style: _G.label(color: Colors.white.withValues(alpha: 0.5), weight: FontWeight.w600)),
        ]),
      );
}

// ─── CountUp ──────────────────────────────────────────────────────────────────

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

// ─── How It Works ─────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.compact});
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
        _EyebrowTitle(eyebrow: 'A BETTER WAY TO RENT',
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
        decoration: BoxDecoration(color: _G.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _G.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(number, style: GoogleFonts.spaceGrotesk(color: _G.accent, fontSize: 13, fontWeight: FontWeight.w800)),
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _G.surface, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 22, color: _G.ink)),
          ]),
          const SizedBox(height: 24),
          Text(title, style: _G.heading(size: 20, color: _G.ink)),
          const SizedBox(height: 10),
          Text(body, style: _G.label()),
        ]),
      );
}

// ─── Category Showcase ────────────────────────────────────────────────────────

class _CategoryShowcase extends StatelessWidget {
  const _CategoryShowcase({required this.compact, required this.onStart,
      required this.categories, required this.equipment});
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
        _EyebrowTitle(eyebrow: 'EQUIPMENT CATALOGUE',
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
              final palette = _catBgPalette[i % _catBgPalette.length];
              final count = _countFor(cat);
              return _CategoryCard(label: cat, icon: _catIcon(cat),
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
              Text('Browse collection', style: _G.label(color: fg.withValues(alpha: 0.6), size: 11, weight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: fg.withValues(alpha: 0.6)),
            ]),
          ]),
        ),
      );
}

// ─── Testimonials ─────────────────────────────────────────────────────────────

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection({required this.compact});
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
        _EyebrowTitle(eyebrow: 'WHAT CLIENTS SAY',
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
        decoration: BoxDecoration(color: _G.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _G.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: List.generate(5, (_) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB020)))),
          const SizedBox(height: 16),
          Text(quote, style: _G.label(color: _G.ink.withValues(alpha: 0.82), size: 14, weight: FontWeight.w500),
              maxLines: 5, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: avatarBg, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(initials, style: GoogleFonts.spaceGrotesk(
                    color: _G.ink, fontWeight: FontWeight.w700, fontSize: 13)))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: GoogleFonts.spaceGrotesk(color: _G.ink, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(role, style: _G.label(size: 11, weight: FontWeight.w500)),
            ]),
          ]),
        ]),
      );
}

// ─── CTA Banner ───────────────────────────────────────────────────────────────

class _CtaBanner extends StatelessWidget {
  const _CtaBanner({required this.onStart, required this.compact});
  final VoidCallback onStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 30 : 52),
      decoration: BoxDecoration(color: _G.accent, borderRadius: BorderRadius.circular(32)),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_copy(), const SizedBox(height: 24), _btn()])
          : Row(children: [Expanded(child: _copy()), const SizedBox(width: 40), _btn()]),
    );
  }

  Widget _copy() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your warehouse\nshouldn\'t need a group chat.', style: _G.heading(size: 36, color: _G.ink)),
        const SizedBox(height: 12),
        Text('Start building a clean, conflict-aware event list right now.',
            style: _G.label(color: _G.ink.withValues(alpha: 0.72), weight: FontWeight.w600)),
      ]);

  Widget _btn() => _PrimaryButton(label: 'Start booking', onTap: onStart, bg: _G.ink, fg: _G.white, filled: true);
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _BrandLockup(dark: true, small: true),
      const Spacer(),
      if (!compact)
        Text('LIVE INVENTORY FOR LIVE EVENTS', style: GoogleFonts.spaceGrotesk(
            color: _G.ink.withValues(alpha: 0.35), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
    ]);
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EyebrowTitle extends StatelessWidget {
  const _EyebrowTitle({required this.eyebrow, required this.title, required this.body, required this.compact});
  final String eyebrow, title, body;
  final bool compact;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow, style: GoogleFonts.spaceGrotesk(
              color: _G.accent, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text(title, style: _G.heading(size: compact ? 36 : 48, color: _G.ink)),
          const SizedBox(height: 16),
          Text(body, style: _G.label(size: 15, weight: FontWeight.w500)),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF1E3226), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: _G.lime),
          const SizedBox(width: 7),
          Text(label, style: GoogleFonts.spaceGrotesk(
              color: _G.lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.9)),
        ]),
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.icon,
      this.filled = false, this.mini = false,
      this.bg = _G.accent, this.fg = _G.ink});
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
      style: FilledButton.styleFrom(backgroundColor: filled ? bg : _G.ink,
          foregroundColor: filled ? fg : Colors.white, padding: padding, shape: shape),
      child: Text(label, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: mini ? 13 : 15)),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.dark, this.small = false});
  final bool dark;
  final bool small;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 30 : 40, height: small ? 30 : 40,
            decoration: BoxDecoration(color: _G.accent, borderRadius: BorderRadius.circular(small ? 9 : 13)),
            child: Icon(Icons.graphic_eq_rounded, size: small ? 18 : 24, color: dark ? _G.ink : _G.white),
          ),
          const SizedBox(width: 10),
          Text('GearGrid', style: GoogleFonts.spaceGrotesk(
              color: dark ? _G.ink : _G.white, fontWeight: FontWeight.w700,
              fontSize: small ? 18 : 22, letterSpacing: -0.8)),
        ],
      );
}
