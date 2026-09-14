import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import 'payment_screen.dart';

// ─── Design tokens (shared) ───────────────────────────────────────────────────
class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle head(
          {double size = 22, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.8,
          height: 1.1);

  static TextStyle body(
          {double size = 13,
          Color color = const Color(0xFF8A9489),
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(
          fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

String _fmtDay(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

String _fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final s = d.hour >= 12 ? 'PM' : 'AM';
  return '$h:${d.minute.toString().padLeft(2, '0')} $s';
}

IconData _catIcon(String cat) => switch (cat.toLowerCase()) {
      'sound' || 'audio' => Icons.speaker_group_rounded,
      'lighting' || 'lights' => Icons.lightbulb_outline_rounded,
      'visual' || 'visuals' || 'screen' => Icons.tv_rounded,
      'furniture' => Icons.weekend_outlined,
      'staging' || 'stage' => Icons.theater_comedy_rounded,
      _ => Icons.inventory_2_outlined,
    };

// ─── Pricing helpers ──────────────────────────────────────────────────────────
const double _platformFee = 99.0;
const double _gstRate = 0.18;

double _calcSubtotal(List<Equipment> items, Map<String, int> qtys) =>
    items.fold(0, (s, i) => s + i.pricePerUnit * (qtys[i.id] ?? 0));

// ─── Screen ───────────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({
    required this.user,
    required this.items,
    required this.quantities,
    required this.start,
    required this.end,
    required this.repository,
    required this.onSlotChange,
    super.key,
  });

  final AppUser user;
  final List<Equipment> items;
  final Map<String, int> quantities;
  final DateTime start;
  final DateTime end;
  final FirestoreRepository repository;
  final VoidCallback onSlotChange;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late final Map<String, int> _qtys;
  final TextEditingController _eventCtrl = TextEditingController();
  final TextEditingController _venueCtrl = TextEditingController();
  final TextEditingController _mapsLinkCtrl = TextEditingController();
  late final AnimationController _fadeAnim;

  @override
  void initState() {
    super.initState();
    _qtys = Map.from(widget.quantities);
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _eventCtrl.dispose();
    _venueCtrl.dispose();
    _mapsLinkCtrl.dispose();
    _fadeAnim.dispose();
    super.dispose();
  }

  List<Equipment> get _cartItems =>
      widget.items.where((i) => (_qtys[i.id] ?? 0) > 0).toList();

  double get _subtotal => _calcSubtotal(_cartItems, _qtys);
  double get _gst => (_subtotal + _platformFee) * _gstRate;
  double get _total => _subtotal + _platformFee + _gst;

  void _updateQty(String id, int delta) {
    setState(() {
      final next = ((_qtys[id] ?? 0) + delta).clamp(0, 99);
      if (next == 0) {
        _qtys.remove(id);
      } else {
        _qtys[id] = next;
      }
    });
  }

  Future<void> _goToPayment() async {
    final event = _eventCtrl.text.trim();
    final venue = _venueCtrl.text.trim();
    if (event.isEmpty) {
      _snack('Please enter an event name.');
      return;
    }
    if (venue.isEmpty) {
      _snack('Please enter the event venue / delivery address.');
      return;
    }
    if (_cartItems.isEmpty) {
      _snack('Your cart is empty.');
      return;
    }

      final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          user: widget.user,
          items: _cartItems,
          quantities: Map.from(_qtys),
          start: widget.start,
          end: widget.end,
          eventName: event,
          venue: venue,
          mapsLink: _mapsLinkCtrl.text.trim().isEmpty ? null : _mapsLinkCtrl.text.trim(),
          subtotal: _subtotal,
          platformFee: _platformFee,
          taxAmount: _gst,
          totalAmount: _total,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // back to storefront → clear cart
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: _C.body(color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: _C.ink,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hPad = 20.0;
    final items = _cartItems;

    return Scaffold(
      backgroundColor: _C.surface,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────────
          _CartAppBar(
              itemCount: items.fold(0, (s, i) => s + (_qtys[i.id] ?? 0))),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slot banner
                    _SlotCard(
                      start: widget.start,
                      end: widget.end,
                      onEdit: () {
                        widget.onSlotChange();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section: Equipment
                    Text('YOUR EQUIPMENT',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _C.muted)),
                    const SizedBox(height: 12),

                    if (items.isEmpty)
                      _EmptyCart()
                    else
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CartItemTile(
                              item: item,
                              qty: _qtys[item.id] ?? 0,
                              onAdd: () => _updateQty(item.id, 1),
                              onRemove: () => _updateQty(item.id, -1),
                            ),
                          )),

                    const SizedBox(height: 24),

                    // Section: Event details
                    Text('EVENT DETAILS',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: _C.muted)),
                    const SizedBox(height: 12),
                    _PField(
                        ctrl: _eventCtrl,
                        label: 'Event name',
                        icon: Icons.celebration_outlined),
                    const SizedBox(height: 10),
                    _PField(
                        ctrl: _venueCtrl,
                        label: 'Venue / delivery address',
                        icon: Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    _PField(
                        ctrl: _mapsLinkCtrl,
                        label: 'Google Maps Link (optional)',
                        icon: Icons.map_outlined),

                    const SizedBox(height: 28),

                    // Section: Price breakdown
                    _PriceBreakdownCard(
                      subtotal: _subtotal,
                      platformFee: _platformFee,
                      gst: _gst,
                      total: _total,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ────────────────────────────────────────────────────────
      bottomSheet: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: BoxDecoration(
                  color: _C.surface,
                  border: Border(
                      top: BorderSide(
                          color: _C.border.withValues(alpha: 0.7))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _PressableButton(
                    onTap: _goToPayment,
                    total: _total,
                  ),
                ),
              ),
            ),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final double total;
  const _PressableButton({required this.onTap, required this.total});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
              color: _C.ink,
              borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Proceed to Pay  ₹${widget.total.round()}',
                style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart App Bar ─────────────────────────────────────────────────────────────

class _CartAppBar extends StatelessWidget {
  const _CartAppBar({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surface,
          border: Border(
            bottom: BorderSide(color: _C.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
              color: _C.ink,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Cart', style: _C.head(size: 22, color: _C.ink)),
                  Text('$itemCount item${itemCount == 1 ? '' : 's'} selected',
                      style: _C.body(size: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slot Card ────────────────────────────────────────────────────────────────

class _SlotCard extends StatelessWidget {
  const _SlotCard(
      {required this.start, required this.end, required this.onEdit});
  final DateTime start, end;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5CC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE89A)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: const Color(0xFFD4EDAB),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF2E6B1A), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EVENT SLOT',
                  style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF4A7A28),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 3),
              Text(
                  '${_fmtDay(start)} · ${_fmtTime(start)} – ${_fmtTime(end)}',
                  style:
                      _C.body(color: _C.ink, size: 13, weight: FontWeight.w800)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Text('Change',
              style: _C.body(
                  color: const Color(0xFF2E6B1A),
                  size: 13,
                  weight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

// ─── Cart Item Tile ───────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });
  final Equipment item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.pricePerUnit * qty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Icon(_catIcon(item.category),
                    size: 22, color: _C.ink)),
          ),
          const SizedBox(width: 14),

          // Name + price per unit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: _C.body(
                        color: _C.ink,
                        size: 14,
                        weight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    item.pricePerUnit > 0
                        ? '₹${item.pricePerUnit.round()} / unit'
                        : item.category,
                    style: _C.body(size: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Stepper + subtotal column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lineTotal > 0)
                Text('₹${lineTotal.round()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: _C.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _Stepper(qty: qty, onAdd: onAdd, onRemove: onRemove),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.qty, required this.onAdd, required this.onRemove});
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _C.ink, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
              icon: qty == 1 ? Icons.delete_rounded : Icons.remove_rounded,
              onTap: onRemove),
          SizedBox(
            width: 26,
            child: Center(
              child: Text('$qty',
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 15, color: const Color(0xFFC8F135)),
        ),
      );
}

// ─── Price Breakdown Card ─────────────────────────────────────────────────────

class _PriceBreakdownCard extends StatelessWidget {
  const _PriceBreakdownCard({
    required this.subtotal,
    required this.platformFee,
    required this.gst,
    required this.total,
  });
  final double subtotal, platformFee, gst, total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Price Breakdown',
                style: _C.head(size: 16, color: _C.ink)),
          ),
          const SizedBox(height: 12),
          _Row('Equipment subtotal', '₹${subtotal.round()}'),
          _Row('Platform fee', '₹${platformFee.round()}',
              note: 'One-time service charge'),
          _Row('GST (18%)', '₹${gst.round()}',
              note: 'On subtotal + platform fee'),
          Divider(
              color: _C.border.withValues(alpha: 0.7),
              height: 24,
              indent: 16,
              endIndent: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _C.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text('Total',
                    style: GoogleFonts.spaceGrotesk(
                        color: _C.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₹${total.round()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFC8F135),
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.note});
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _C.body(color: _C.ink, weight: FontWeight.w600)),
                if (note != null) Text(note!, style: _C.body(size: 10)),
              ],
            ),
          ),
          Text(value,
              style: _C.body(
                  color: _C.ink,
                  size: 14,
                  weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Premium text field ───────────────────────────────────────────────────────

class _PField extends StatelessWidget {
  const _PField(
      {required this.ctrl, required this.label, required this.icon});
  final TextEditingController ctrl;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: _C.body(color: _C.ink, size: 14, weight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _C.body(size: 13),
        prefixIcon: Icon(icon, size: 18, color: _C.muted),
        filled: true,
        fillColor: _C.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border, width: 1.0)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: _C.muted),
            const SizedBox(height: 16),
            Text('Cart is empty',
                style: _C.head(size: 18, color: _C.muted)),
            const SizedBox(height: 8),
            Text('Go back and add equipment to your event.',
                style: _C.body(size: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
int _randomSeed() => Random().nextInt(999999);
