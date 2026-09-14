import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import '../widgets/live_pulse_dot.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'profile_settings_screen.dart';
import 'help_support_screen.dart';

// ─── Design tokens (mirrored from landing) ────────────────────────────────────
class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFF6B35);
  static const lime = Color(0xFFC8F135);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle brand(
          {double size = 22, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.8);

  static TextStyle head(
          {double size = 26, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -1.0,
          height: 1.1);

  static TextStyle body(
          {double size = 13,
          Color color = const Color(0xFF8A9489),
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

IconData _catIcon(String cat) {
  final l = cat.toLowerCase();
  if (l.contains('light')) return Icons.lightbulb_outline_rounded;
  if (l.contains('sound') || l.contains('audio')) return Icons.speaker_group_rounded;
  if (l.contains('visual')) return Icons.tv_rounded;
  if (l.contains('furn')) return Icons.weekend_outlined;
  if (l.contains('power')) return Icons.bolt_rounded;
  return Icons.category_outlined;
}

String _formatDay(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:${date.minute.toString().padLeft(2, '0')} $suffix';
}

IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
      'sound' || 'voice' || 'audio' => Icons.speaker_group_rounded,
      'lighting' || 'lights' => Icons.lightbulb_outline_rounded,
      'visual' || 'visuals' || 'screen' => Icons.tv_rounded,
      'furniture' => Icons.weekend_outlined,
      'staging' || 'stage' => Icons.theater_comedy_rounded,
      'power' => Icons.bolt_rounded,
      _ => Icons.inventory_2_outlined,
    };

String _formatPrice(double price) {
  if (price <= 0) return 'Price on request';
  final p = price.round();
  if (p >= 1000) return '₹${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}k / unit';
  return '₹$p / unit';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class ClientStorefrontScreen extends StatefulWidget {
  const ClientStorefrontScreen({required this.user, super.key});
  final AppUser user;

  @override
  State<ClientStorefrontScreen> createState() => _ClientStorefrontScreenState();
}

class _ClientStorefrontScreenState extends State<ClientStorefrontScreen>
    with TickerProviderStateMixin {
  final _repository = FirestoreRepository();
  final _cart = <String, int>{};
  late DateTime _start;
  late DateTime _end;
  List<Equipment> _inventory = [];
  Map<String, int> _reservedUnits = {};
  StreamSubscription<List<Equipment>>? _equipmentSub;
  StreamSubscription<Map<String, int>>? _reservationSub;
  String _selectedCategory = 'All';
  String? _connectionIssue;
  int _selectedTab = 0;

  late AnimationController _cartBarAnim;
  late AnimationController _cardAnim;
  bool _cartVisible = false;

  @override
  void initState() {
    super.initState();
    _cartBarAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18);
    _end = _start.add(const Duration(hours: 5));

    _equipmentSub = _repository.watchEquipment().listen((inv) {
      if (!mounted) return;
      setState(() {
        _inventory = inv;
        _connectionIssue = null;
      });
    }, onError: _onError);
    _watchAvailability();
  }

  @override
  void dispose() {
    _cartBarAnim.dispose();
    _cardAnim.dispose();
    _equipmentSub?.cancel();
    _reservationSub?.cancel();
    super.dispose();
  }

  void _watchAvailability() {
    _reservationSub?.cancel();
    _reservationSub = _repository
        .watchReservedUnits(start: _start, end: _end)
        .listen((reserved) {
      if (!mounted) return;
      setState(() {
        _reservedUnits = reserved;
        _connectionIssue = null;
      });
    }, onError: _onError);
  }

  void _onError(Object e) {
    if (!mounted) return;
    setState(() => _connectionIssue = 'Live availability is reconnecting…');
  }

  int _available(Equipment e) =>
      (e.totalUnits - (_reservedUnits[e.id] ?? 0)).clamp(0, e.totalUnits);

  int get _cartCount => _cart.values.fold(0, (s, v) => s + v);
  List<Equipment> get _cartItems =>
      _inventory.where((i) => (_cart[i.id] ?? 0) > 0).toList();
  List<String> get _categories =>
      ['All', ...{for (final i in _inventory) i.category}];
  List<Equipment> get _visible => _selectedCategory == 'All'
      ? _inventory
      : _inventory.where((i) => i.category == _selectedCategory).toList();
  bool get _cartOk =>
      _cartItems.isNotEmpty &&
      _cartItems.every((i) => (_cart[i.id] ?? 0) <= _available(i));

  double get _cartTotal => _cartItems.fold(
      0, (sum, i) => sum + (i.pricePerUnit * (_cart[i.id] ?? 0)));

  void _changeQty(Equipment e, int delta) {
    final next = ((_cart[e.id] ?? 0) + delta).clamp(0, _available(e));
    setState(() {
      if (next == 0) {
        _cart.remove(e.id);
      } else {
        _cart[e.id] = next;
      }
      final hasItems = _cart.isNotEmpty;
      if (hasItems && !_cartVisible) {
        _cartVisible = true;
        _cartBarAnim.forward();
      } else if (!hasItems && _cartVisible) {
        _cartVisible = false;
        _cartBarAnim.reverse();
      }
    });
  }

  Future<void> _pickSlot() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: _C.accent, brightness: Brightness.light),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _end = _start.add(const Duration(hours: 5));
    });
    _watchAvailability();
  }

  Future<void> _openCheckout() async {
    if (_cartCount == 0) return;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          user: widget.user,
          items: _inventory,
          quantities: _cart,
          start: _start,
          end: _end,
          repository: _repository,
          onSlotChange: _pickSlot,
        ),
      ),
    );

    // If payment was successful, clear the cart.
    if (success == true && mounted) {
      setState(() {
        _cart.clear();
        _cartVisible = false;
        _cartBarAnim.reverse();
        _selectedTab = 1; // Go to orders tab
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final hPad = compact ? 18.0 : 44.0;

    return Scaffold(
      backgroundColor: _C.surface,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _C.white,
          border: Border(
            top: BorderSide(color: _C.border.withValues(alpha: 0.8), width: 1),
          ),
        ),
        // Pad for home indicator without adding a fixed height
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Browse',
              selected: _selectedTab == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
            ),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'My Orders',
              selected: _selectedTab == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          Stack(
            children: [
              // ── Main scroll ──────────────────────────────────────────────────
              CustomScrollView(
                slivers: [
                  // Sticky header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      minHeight: 64 + MediaQuery.paddingOf(context).top,
                      maxHeight: 64 + MediaQuery.paddingOf(context).top,
                      child: _TopBar(
                        user: widget.user,
                        cartCount: _cartCount,
                        connectionIssue: _connectionIssue,
                        hPad: hPad,
                        onCartTap: _cartCount > 0 ? _openCheckout : null,
                        onSignOut: FirebaseAuth.instance.signOut,
                      ),
                    ),
                  ),

                  // Event slot banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      child: _SlotBanner(
                          start: _start, end: _end, onChange: _pickSlot),
                    ),
                  ),


                  // Hero banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                      child: _StoreHeroBanner(
                          user: widget.user,
                          compact: compact,
                          cartCount: _cartCount,
                          cartTotal: _cartTotal),
                    ),
                  ),

                  // Section header + category rail
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Build your event list',
                              style: _C.head(size: 28, color: _C.ink)),
                          const SizedBox(height: 4),
                          Text(
                              'Every number is live for your selected event window.',
                              style: _C.body()),
                          const SizedBox(height: 18),
                          _CategoryRail(
                            categories: _categories,
                            selected: _selectedCategory,
                            onSelect: (c) =>
                                setState(() => _selectedCategory = c),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // Equipment grid
                  if (_visible.isEmpty)
                    const SliverToBoxAdapter(
                      child: _LoadingGrid(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, 0, hPad, _cartCount > 0 ? 160 : 48),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final eq = _visible[i];
                            return _EquipmentCard(
                              equipment: eq,
                              available: _available(eq),
                              cartQty: _cart[eq.id] ?? 0,
                              onAdd: () => _changeQty(eq, 1),
                              onRemove: () => _changeQty(eq, -1),
                              animController: _cardAnim,
                              index: i,
                            );
                          },
                          childCount: _visible.length,
                        ),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: compact ? 380 : 340,
                          mainAxisExtent: 330,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Floating cart bar ────────────────────────────────────────────
              Positioned(
                left: hPad - 6,
                right: hPad - 6,
                bottom: 20,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: _cartBarAnim, curve: Curves.elasticOut)),
                  child: _CartBar(
                    itemCount: _cartCount,
                    itemKinds: _cartItems.length,
                    cartTotal: _cartTotal,
                    canRequest: _cartOk,
                    onPressed: _openCheckout,
                  ),
                ),
              ),
            ],
          ),
          OrderHistoryScreen(
            user: widget.user,
            repository: _repository,
          ),
        ],
      ),
    );
  }
}

// ─── Sticky Header Delegate ───────────────────────────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate(
      {required this.minHeight,
      required this.maxHeight,
      required this.child});
  final double minHeight, maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      maxHeight != old.maxHeight || minHeight != old.minHeight || child != old.child;
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.cartCount,
    required this.connectionIssue,
    required this.hPad,
    required this.onSignOut,
    this.onCartTap,
  });
  final AppUser user;
  final int cartCount;
  final String? connectionIssue;
  final double hPad;
  final VoidCallback? onCartTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final syncing = connectionIssue != null;
    return Container(
      color: _C.surface.withValues(alpha: 0.96),
      child: Column(
        children: [
          // ── Reconnect indicator — slim 3px stripe, no layout shift ──────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 3,
            color: syncing
                ? const Color(0xFFFF9800)
                : const Color(0xFF43A047),
          ),

          // ── Status Bar Padding ──────────────────────────────────────────
          SizedBox(height: MediaQuery.paddingOf(context).top),

          // ── Main row ────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  // Brand
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: _C.accent,
                        borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.graphic_eq_rounded,
                        color: _C.ink, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('GearGrid', style: _C.brand()),

                  const Spacer(),

                  // Right side — fixed width, never overflows
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sync dot (tiny — just a coloured circle)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: syncing
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF43A047),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar with PopupMenu
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: _C.white,
                        elevation: 12,
                        onSelected: (value) {
                          if (value == 'logout') {
                            onSignOut();
                          } else if (value == 'profile') {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
                          } else if (value == 'help') {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 20, color: _C.ink),
                                const SizedBox(width: 12),
                                Text('Profile Settings', style: _C.body()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'help',
                            child: Row(
                              children: [
                                const Icon(Icons.help_outline_rounded, size: 20, color: _C.ink),
                                const SizedBox(width: 12),
                                Text('Help & Support', style: _C.body()),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                                const SizedBox(width: 12),
                                Text('Sign Out', style: _C.body(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: _C.ink,
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.spaceGrotesk(
                                  color: _C.lime,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
              height: 1,
              thickness: 1,
              color: _C.border.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

// ─── Slot Banner ──────────────────────────────────────────────────────────────

class _SlotBanner extends StatelessWidget {
  const _SlotBanner(
      {required this.start, required this.end, required this.onChange});
  final DateTime start, end;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5CC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCDE89A)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFD4EDAB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF2E6B1A), size: 18),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR EVENT WINDOW',
                      style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF4A7A28),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatDay(start)} · ${_formatTime(start)} – ${_formatTime(end)}',
                    style: _C.body(
                        color: _C.ink, size: 13, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFF2E6B1A),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Change',
                    style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.edit_calendar_rounded,
                    size: 13, color: Colors.white),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Store Hero Banner ────────────────────────────────────────────────────────

class _StoreHeroBanner extends StatelessWidget {
  const _StoreHeroBanner({
    required this.user,
    required this.compact,
    required this.cartCount,
    required this.cartTotal,
  });
  final AppUser user;
  final bool compact;
  final int cartCount;
  final double cartTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _C.ink, borderRadius: BorderRadius.circular(28)),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _copy(),
              const SizedBox(height: 20),
              _badge()
            ])
          : Row(children: [
              Expanded(child: _copy()),
              const SizedBox(width: 24),
              _badge()
            ]),
    );
  }

  Widget _copy() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.displayName.split(' ').first}\'s\nevent, properly stocked.',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 30,
                height: 1.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Add what you need. We keep the warehouse count in sync while you build.',
            style: _C.body(color: const Color(0xFFB0BDB0)),
          ),
        ],
      );

  Widget _badge() => Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF243328),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: _C.lime, size: 22),
            const SizedBox(height: 16),
            Text('$cartCount',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700)),
            Text('items in list',
                style: _C.body(
                    color: const Color(0xFF8EA18E), size: 11)),
            if (cartTotal > 0) ...[
              const SizedBox(height: 6),
              Text(
                '₹${cartTotal.round()}',
                style: GoogleFonts.spaceGrotesk(
                    color: _C.lime,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );
}

// ─── Category Rail ────────────────────────────────────────────────────────────

class _CategoryRail extends StatelessWidget {
  const _CategoryRail(
      {required this.categories,
      required this.selected,
      required this.onSelect});
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _C.ink : _C.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected ? _C.ink : _C.border, width: 1.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _C.ink.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat != 'All') ...[
                    Icon(_categoryIcon(cat),
                        size: 14,
                        color:
                            isSelected ? _C.lime : _C.muted),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.manrope(
                      color: isSelected ? Colors.white : _C.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Equipment Card ───────────────────────────────────────────────────────────

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.equipment,
    required this.available,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
    required this.animController,
    required this.index,
  });
  final Equipment equipment;
  final int available;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final AnimationController animController;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.07).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: animController,
      curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(animation),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showEquipmentDetails(context, equipment, available);
          },
          child: _CardBody(
            equipment: equipment,
            available: available,
            cartQty: cartQty,
            onAdd: onAdd,
            onRemove: onRemove,
          ),
        ),
      ),
    );
  }
}

void _showEquipmentDetails(BuildContext context, Equipment equipment, int available) {
  showModalBottomSheet(
    context: context,
    backgroundColor: _C.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.paddingOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(_catIcon(equipment.category), color: equipment.accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(equipment.name, style: _C.head(size: 20)),
                    Text(equipment.powerProfile, style: _C.body(size: 13, color: _C.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('DESCRIPTION',
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: _C.muted)),
          const SizedBox(height: 8),
          Text(equipment.description, style: _C.body(size: 14, color: _C.ink, weight: FontWeight.w500)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price', style: _C.body(size: 14)),
              Text(_formatPrice(equipment.pricePerUnit), style: _C.head(size: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available units', style: _C.body(size: 14)),
              AvailabilityBadge(available: available),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.equipment,
    required this.available,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
  });
  final Equipment equipment;
  final int available;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inCart = cartQty > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: inCart ? _C.ink.withValues(alpha: 0.5) : _C.border,
          width: inCart ? 2.0 : 1.0,
        ),
        boxShadow: inCart
            ? [
                BoxShadow(
                    color: _C.ink.withValues(alpha: 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image / Illustration zone ────────────────────────────────
          _CardImageZone(equipment: equipment, inCart: inCart),

          // ── Info ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _C.head(size: 15, color: _C.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equipment.powerProfile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _C.body(size: 10, weight: FontWeight.w700),
                  ),
                  const Spacer(),

                  // Price row
                  Text(
                    _formatPrice(equipment.pricePerUnit),
                    style: GoogleFonts.spaceGrotesk(
                        color: _C.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  // Availability + ADD/qty control
                  Row(
                    children: [
                      AvailabilityBadge(available: available),
                      const Spacer(),
                      _QtyControl(
                        qty: cartQty,
                        enabled: available > 0,
                        onAdd: onAdd,
                        onRemove: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardImageZone extends StatelessWidget {
  const _CardImageZone(
      {required this.equipment, required this.inCart});
  final Equipment equipment;
  final bool inCart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: equipment.accent.withValues(alpha: 0.55),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: equipment.imageUrl != null
              ? ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    equipment.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        _categoryIcon(equipment.category),
                        size: 54,
                        color: _C.ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    _categoryIcon(equipment.category),
                    size: 54,
                    color: _C.ink.withValues(alpha: 0.65),
                  ),
                ),
        ),

        // Category badge
        Positioned(
          left: 11,
          top: 11,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              equipment.category.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                  color: _C.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9),
            ),
          ),
        ),

        // In-cart checkmark
        if (inCart)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _C.ink, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_rounded,
                  color: _C.lime, size: 14),
            ),
          ),
      ],
    );
  }
}

// ─── Quantity Control ─────────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  const _QtyControl(
      {required this.qty,
      required this.enabled,
      required this.onAdd,
      required this.onRemove});
  final int qty;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: qty == 0
          ? GestureDetector(
              key: const ValueKey('add'),
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onAdd();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      enabled ? _C.ink : const Color(0xFFECE9E0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'ADD',
                  style: GoogleFonts.spaceGrotesk(
                    color: enabled
                        ? _C.lime
                        : const Color(0xFFBBB8AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('stepper'),
              decoration: BoxDecoration(
                  color: _C.ink,
                  borderRadius: BorderRadius.circular(11)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TinyBtn(icon: Icons.remove_rounded, onTap: onRemove),
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Text(
                        '$qty',
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  _TinyBtn(
                      icon: Icons.add_rounded,
                      onTap: enabled ? onAdd : null),
                ],
              ),
            ),
    );
  }
}

class _TinyBtn extends StatelessWidget {
  const _TinyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon,
              size: 16,
              color: onTap == null ? Colors.white24 : _C.lime),
        ),
      );
}

// ─── Cart Bar ─────────────────────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.itemCount,
    required this.itemKinds,
    required this.cartTotal,
    required this.canRequest,
    required this.onPressed,
  });
  final int itemCount, itemKinds;
  final double cartTotal;
  final bool canRequest;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x55000000),
              blurRadius: 30,
              offset: Offset(0, 12))
        ],
      ),
      child: Row(
        children: [
          // Count badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: _C.accent,
                borderRadius: BorderRadius.circular(15)),
            child: Center(
              child: Text(
                '$itemCount',
                style: GoogleFonts.spaceGrotesk(
                    color: _C.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 13),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemKinds equipment type${itemKinds == 1 ? '' : 's'}',
                  style: _C.body(
                      color: Colors.white, weight: FontWeight.w800),
                ),
                Text(
                  canRequest
                      ? (cartTotal > 0 ? '₹${cartTotal.round()} · Ready to book' : 'Ready to review')
                      : 'Some items need attention',
                  style: _C.body(
                      color: canRequest
                          ? const Color(0xFF9DD97A)
                          : const Color(0xFFFFAA88),
                      size: 11,
                      weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // CTA
          GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                  color: _C.lime,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Cart',
                      style: GoogleFonts.manrope(
                          color: _C.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: _C.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? const Color(0xFF0C1710) : const Color(0xFF8A9489),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF0C1710) : const Color(0xFF8A9489),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: selected ? 18 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── Loading Grid ─────────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF0C1710)),
        ),
      );
}
