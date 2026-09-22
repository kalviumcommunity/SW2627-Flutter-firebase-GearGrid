import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import '../theme/landing_theme.dart';
import '../widgets/landing_category_showcase.dart';
import '../widgets/landing_cta_banner.dart';
import '../widgets/landing_footer.dart';
import '../widgets/landing_hero.dart';
import '../widgets/landing_how_it_works.dart';
import '../widgets/landing_nav_bar.dart';
import '../widgets/landing_stat_rail.dart';
import '../widgets/landing_testimonials.dart';

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
      (list) {
        if (mounted) setState(() => _equipment = list);
      },
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
      backgroundColor: LandingTheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 56,
                    MediaQuery.paddingOf(context).top + 88,
                    compact ? 20 : 56,
                    60),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    LandingHero(
                        onStart: widget.onStart,
                        compact: compact,
                        heroFade: _heroFade,
                        floatingCards: _floatingCards,
                        equipment: _equipment,
                        totalUnits: _totalUnits),
                    const SizedBox(height: 32),
                    LandingStatRail(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    LandingHowItWorks(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    LandingCategoryShowcase(
                        compact: compact,
                        onStart: widget.onStart,
                        categories: _uniqueCategories,
                        equipment: _equipment),
                    SizedBox(height: compact ? 64 : 96),
                    LandingTestimonials(compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    LandingCtaBanner(onStart: widget.onStart, compact: compact),
                    SizedBox(height: compact ? 64 : 96),
                    LandingFooter(compact: compact),
                  ]),
                ),
              )
            ],
          ),
          LandingNavBar(
              scrolled: _navScrolled,
              compact: compact,
              onStart: widget.onStart),
        ],
      ),
    );
  }
}
