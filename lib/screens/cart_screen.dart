import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';
import '../theme/client_theme.dart';
import '../widgets/cart_app_bar.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/empty_cart_state.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/pressable_checkout_button.dart';
import '../widgets/price_breakdown_card.dart';
import '../widgets/slot_card.dart';
import 'payment_screen.dart';

const double _platformFee = 99.0;
const double _gstRate = 0.18;

double _calcSubtotal(List<Equipment> items, Map<String, int> qtys) =>
    items.fold(0, (s, i) => s + i.pricePerUnit * (qtys[i.id] ?? 0));

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
      Navigator.pop(context, true);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: ClientTheme.body(color: Colors.white, weight: FontWeight.w700)),
          backgroundColor: ClientTheme.ink,
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
      backgroundColor: ClientTheme.surface,
      body: Column(
        children: [
          CartAppBar(
              itemCount: items.fold(0, (s, i) => s + (_qtys[i.id] ?? 0))),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlotCard(
                      start: widget.start,
                      end: widget.end,
                      onEdit: () {
                        widget.onSlotChange();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('YOUR EQUIPMENT',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: ClientTheme.muted)),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const EmptyCartState()
                    else
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: CartItemTile(
                              item: item,
                              qty: _qtys[item.id] ?? 0,
                              onAdd: () => _updateQty(item.id, 1),
                              onRemove: () => _updateQty(item.id, -1),
                            ),
                          )),
                    const SizedBox(height: 24),
                    Text('EVENT DETAILS',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: ClientTheme.muted)),
                    const SizedBox(height: 12),
                    PremiumTextField(
                        ctrl: _eventCtrl,
                        label: 'Event name',
                        icon: Icons.celebration_outlined),
                    const SizedBox(height: 10),
                    PremiumTextField(
                        ctrl: _venueCtrl,
                        label: 'Venue / delivery address',
                        icon: Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    PremiumTextField(
                        ctrl: _mapsLinkCtrl,
                        label: 'Google Maps Link (optional)',
                        icon: Icons.map_outlined),
                    const SizedBox(height: 28),
                    PriceBreakdownCard(
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
      bottomSheet: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: BoxDecoration(
                  color: ClientTheme.surface,
                  border: Border(
                      top: BorderSide(
                          color: ClientTheme.border.withValues(alpha: 0.7))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PressableCheckoutButton(
                    onTap: _goToPayment,
                    total: _total,
                  ),
                ),
              ),
            ),
    );
  }
}
