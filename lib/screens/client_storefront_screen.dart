import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import '../theme/client_theme.dart';
import '../widgets/category_rail.dart';
import '../widgets/equipment_catalog_card.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/slot_banner.dart';
import '../widgets/store_hero_banner.dart';
import '../widgets/storefront_top_bar.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

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
              seedColor: ClientTheme.accent, brightness: Brightness.light),
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
      backgroundColor: ClientTheme.surface,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ClientTheme.white,
          border: Border(
            top: BorderSide(color: ClientTheme.border.withValues(alpha: 0.8), width: 1),
          ),
        ),
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
              CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyHeaderDelegate(
                      minHeight: 64 + MediaQuery.paddingOf(context).top,
                      maxHeight: 64 + MediaQuery.paddingOf(context).top,
                      child: StorefrontTopBar(
                        user: widget.user,
                        cartCount: _cartCount,
                        connectionIssue: _connectionIssue,
                        hPad: hPad,
                        onCartTap: _cartCount > 0 ? _openCheckout : null,
                        onSignOut: FirebaseAuth.instance.signOut,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      child: SlotBanner(start: _start, end: _end, onChange: _pickSlot),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                      child: StoreHeroBanner(
                          user: widget.user,
                          compact: compact,
                          cartCount: _cartCount,
                          cartTotal: _cartTotal),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Build your event list',
                              style: ClientTheme.head(size: 28, color: ClientTheme.ink)),
                          const SizedBox(height: 4),
                          Text(
                              'Every number is live for your selected event window.',
                              style: ClientTheme.body()),
                          const SizedBox(height: 18),
                          CategoryRail(
                            categories: _categories,
                            selected: _selectedCategory,
                            onSelect: (c) => setState(() => _selectedCategory = c),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
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
                            return EquipmentCatalogCard(
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
                  child: FloatingCartBar(
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
                color: selected ? ClientTheme.ink : ClientTheme.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? ClientTheme.ink : ClientTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: selected ? 18 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  color: ClientTheme.accent,
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

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: ClientTheme.ink),
        ),
      );
}
