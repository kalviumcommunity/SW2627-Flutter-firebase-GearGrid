import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/equipment.dart';
import '../services/firestore_repository.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
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
          letterSpacing: -0.8);

  static TextStyle body(
          {double size = 13,
          Color color = const Color(0xFF8A9489),
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(
          fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

enum _PayMethod { upi, card, wallet }

// ─── Screen ──────────────────────────────────────────────────────────────────

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.user,
    required this.items,
    required this.quantities,
    required this.start,
    required this.end,
    required this.eventName,
    required this.venue,
    this.mapsLink,
    required this.subtotal,
    required this.platformFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.repository,
    super.key,
  });

  final AppUser user;
  final List<Equipment> items;
  final Map<String, int> quantities;
  final DateTime start;
  final DateTime end;
  final String eventName;
  final String venue;
  final String? mapsLink;
  final double subtotal;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final FirestoreRepository repository;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

typedef _Phase = int;
const _phaseIdle = 0;
const _phaseProcessing = 1;
const _phaseSuccess = 2;
const _phaseError = 3;

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  _PayMethod _method = _PayMethod.upi;
  _Phase _phase = _phaseIdle;
  String? _errorMsg;
  String? _bookingId;

  // UPI
  final _upiCtrl = TextEditingController();
  String _selectedUpiApp = '';

  // Card
  final _cardNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Animation
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale =
        CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    _cardNumCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    // Validate inputs
    if (_method == _PayMethod.upi &&
        _selectedUpiApp.isEmpty &&
        _upiCtrl.text.trim().isEmpty) {
      _setError('Choose a UPI app or enter your UPI ID.');
      return;
    }
    if (_method == _PayMethod.card) {
      final raw = _cardNumCtrl.text.replaceAll(' ', '');
      if (raw.length < 16) {
        _setError('Please enter a valid 16-digit card number.');
        return;
      }
      if (_expiryCtrl.text.length < 5) {
        _setError('Enter a valid expiry (MM/YY).');
        return;
      }
      if (_cvvCtrl.text.length < 3) {
        _setError('Enter a valid 3-digit CVV.');
        return;
      }
    }

    setState(() {
      _phase = _phaseProcessing;
      _errorMsg = null;
    });

    // Simulate payment processing (2 seconds)
    await Future.delayed(const Duration(milliseconds: 2200));

    // Create booking in Firestore
    _bookingId = 'bk-${DateTime.now().microsecondsSinceEpoch}';
    final paymentId =
        'pay_${Random().nextInt(999999999).toString().padLeft(9, '0')}';
    final paymentMethod = switch (_method) {
      _PayMethod.upi => _selectedUpiApp.isNotEmpty ? _selectedUpiApp : 'UPI',
      _PayMethod.card => 'Card',
      _PayMethod.wallet => 'Wallet',
    };

    try {
      await widget.repository.createBooking(
        Booking(
          id: _bookingId!,
          clientId: widget.user.id,
          clientName: widget.user.displayName,
          eventName: widget.eventName,
          venue: widget.venue,
          start: widget.start,
          end: widget.end,
          status: BookingStatus.pending,
          requestedUnits: Map.from(widget.quantities),
          subtotal: widget.subtotal,
          platformFee: widget.platformFee,
          taxAmount: widget.taxAmount,
          totalAmount: widget.totalAmount,
          paymentId: paymentId,
          paymentMethod: paymentMethod,
          mapsLink: widget.mapsLink,
        ),
      );

      if (!mounted) return;
      setState(() => _phase = _phaseSuccess);
      _checkAnim.forward();
      HapticFeedback.mediumImpact();

      // Auto-dismiss to storefront after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      _setError('Payment processed, but we had trouble saving your order. Please contact support.');
    }
  }

  void _setError(String msg) {
    setState(() {
      _phase = _phaseError;
      _errorMsg = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _phase == _phaseSuccess
            ? _SuccessView(
                key: const ValueKey('success'),
                total: widget.totalAmount,
                eventName: widget.eventName,
                bookingId: _bookingId ?? '',
                onContinue: () => Navigator.pop(context, true),
                scaleAnim: _checkScale,
              )
            : _phase == _phaseProcessing
                ? Container(
                    key: const ValueKey('processing'),
                    color: _C.ink,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFC8F135)),
                          const SizedBox(height: 24),
                          Text('Processing payment...',
                              style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                : _PaymentForm(
                    key: const ValueKey('form'),
                    totalAmount: widget.totalAmount,
                    eventName: widget.eventName,
                    items: widget.items,
                    quantities: widget.quantities,
                    method: _method,
                    onMethodChange: (m) => setState(() => _method = m),
                    selectedUpiApp: _selectedUpiApp,
                    onUpiAppSelect: (a) => setState(() => _selectedUpiApp = a),
                    upiCtrl: _upiCtrl,
                    cardNumCtrl: _cardNumCtrl,
                    expiryCtrl: _expiryCtrl,
                    cvvCtrl: _cvvCtrl,
                    nameCtrl: _nameCtrl,
                    processing: _phase == _phaseProcessing,
                    errorMsg: _phase == _phaseError ? _errorMsg : null,
                    onPay: _pay,
                  ),
      ),
    );
  }
}

// ─── Payment Form ─────────────────────────────────────────────────────────────

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.totalAmount,
    required this.eventName,
    required this.items,
    required this.quantities,
    required this.method,
    required this.onMethodChange,
    required this.selectedUpiApp,
    required this.onUpiAppSelect,
    required this.upiCtrl,
    required this.cardNumCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.nameCtrl,
    required this.processing,
    required this.errorMsg,
    required this.onPay,
    super.key,
  });

  final double totalAmount;
  final String eventName;
  final List<Equipment> items;
  final Map<String, int> quantities;
  final _PayMethod method;
  final ValueChanged<_PayMethod> onMethodChange;
  final String selectedUpiApp;
  final ValueChanged<String> onUpiAppSelect;
  final TextEditingController upiCtrl, cardNumCtrl, expiryCtrl, cvvCtrl,
      nameCtrl;
  final bool processing;
  final String? errorMsg;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: Column(
        children: [
          // App bar
          SafeArea(
            bottom: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: _C.surface,
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _C.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.border)),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: _C.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Checkout',
                          style: _C.head(size: 20, color: _C.ink)),
                      Text('Pay ₹${totalAmount.round()} for $eventName',
                          style: _C.body(size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_rounded,
                        color: Color(0xFF2E7D32), size: 12),
                    const SizedBox(width: 4),
                    Text('Secure',
                        style: GoogleFonts.manrope(
                            color: const Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
                  _OrderSummaryCard(
                      items: items,
                      quantities: quantities,
                      total: totalAmount),
                  const SizedBox(height: 22),

                  // Method tabs
                  Text('Payment Method',
                      style: _C.head(size: 18, color: _C.ink)),
                  const SizedBox(height: 12),
                  _MethodTabs(
                      selected: method, onSelect: onMethodChange),
                  const SizedBox(height: 16),

                  // Method body
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: method == _PayMethod.upi
                        ? _UpiTab(
                            key: const ValueKey('upi'),
                            ctrl: upiCtrl,
                            selectedApp: selectedUpiApp,
                            onAppSelect: onUpiAppSelect,
                          )
                        : method == _PayMethod.card
                            ? _CardTab(
                                key: const ValueKey('card'),
                                numCtrl: cardNumCtrl,
                                expiryCtrl: expiryCtrl,
                                cvvCtrl: cvvCtrl,
                                nameCtrl: nameCtrl,
                              )
                            : _WalletTab(key: const ValueKey('wallet')),
                  ),

                  // Error
                  if (errorMsg != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEE8E5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFCDD2))),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFC62828), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(errorMsg!,
                              style: _C.body(
                                  color: const Color(0xFFC62828),
                                  size: 12,
                                  weight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Pay CTA
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          color: _C.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: processing ? null : onPay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: processing
                          ? _C.ink.withValues(alpha: 0.55)
                          : _C.ink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: processing
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white)),
                                const SizedBox(width: 14),
                                Text('Processing payment…',
                                    style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                              ],
                            )
                          : Text(
                              'Pay  ₹${totalAmount.round()}',
                              style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔒 256-bit SSL secured · No card data stored',
                style: _C.body(size: 10, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Summary Card ───────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard(
      {required this.items, required this.quantities, required this.total});
  final List<Equipment> items;
  final Map<String, int> quantities;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _C.ink,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ORDER SUMMARY',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final qty = quantities[item.id] ?? 0;
            final lineTotal = item.pricePerUnit * qty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(item.name,
                    style: _C.body(
                        color: Colors.white, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('  ×$qty',
                    style: _C.body(
                        color: const Color(0xFF8A9489),
                        size: 12)),
                const Spacer(),
                if (lineTotal > 0)
                  Text('₹${lineTotal.round()}',
                      style: _C.body(
                          color: Colors.white,
                          size: 13,
                          weight: FontWeight.w700)),
              ]),
            );
          }),
          const Divider(color: Colors.white12, height: 20),
          Row(children: [
            Text('Total to pay', style: _C.body(color: Colors.white70, size: 12)),
            Text(
              '₹${total.round()}',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text('₹${total.round()}',
                style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFFC8F135),
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

// ─── Method Tabs ──────────────────────────────────────────────────────────────

class _MethodTabs extends StatelessWidget {
  const _MethodTabs({required this.selected, required this.onSelect});
  final _PayMethod selected;
  final ValueChanged<_PayMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(99),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _Tab(
              label: 'UPI',
              active: selected == _PayMethod.upi,
              onTap: () { HapticFeedback.selectionClick(); onSelect(_PayMethod.upi); }),
          _Tab(
              label: 'Card',
              active: selected == _PayMethod.card,
              onTap: () { HapticFeedback.selectionClick(); onSelect(_PayMethod.card); }),
          _Tab(
              label: 'Wallet',
              active: selected == _PayMethod.wallet,
              onTap: () { HapticFeedback.selectionClick(); onSelect(_PayMethod.wallet); }),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _C.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.manrope(
                    color: active ? Colors.white : _C.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

// ─── UPI Tab ──────────────────────────────────────────────────────────────────

const _upiApps = [
  ('GPay', Color(0xFF4285F4), Icons.g_mobiledata_rounded),
  ('PhonePe', Color(0xFF5F259F), Icons.phone_android_rounded),
  ('Paytm', Color(0xFF00BAF2), Icons.account_balance_wallet_rounded),
  ('BHIM', Color(0xFF003087), Icons.payment_rounded),
];

class _UpiTab extends StatelessWidget {
  const _UpiTab(
      {required this.ctrl,
      required this.selectedApp,
      required this.onAppSelect,
      super.key});
  final TextEditingController ctrl;
  final String selectedApp;
  final ValueChanged<String> onAppSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay using UPI app',
              style: _C.body(
                  color: _C.ink, size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 14),

          // UPI app grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _upiApps.map((app) {
              final isSelected = selectedApp == app.$1;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onAppSelect(app.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? app.$2.withValues(alpha: 0.1)
                          : const Color(0xFFF8F7F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isSelected ? app.$2 : _C.border,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(app.$3, color: app.$2, size: 26),
                        const SizedBox(height: 4),
                        Text(app.$1,
                            style: GoogleFonts.manrope(
                                color: _C.ink,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('or enter UPI ID',
                  style: TextStyle(color: Color(0xFF8A9489), fontSize: 11)),
            ),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 12),

          TextField(
            controller: ctrl,
            style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _C.ink),
            decoration: InputDecoration(
              hintText: 'yourname@bank',
              hintStyle: GoogleFonts.manrope(
                  color: _C.muted, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8F7F4),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _C.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _C.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.ink, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              suffixIcon:
                  const Icon(Icons.verified_user_outlined, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Tab ─────────────────────────────────────────────────────────────────

class _CardTab extends StatelessWidget {
  const _CardTab({
    required this.numCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.nameCtrl,
    super.key,
  });
  final TextEditingController numCtrl, expiryCtrl, cvvCtrl, nameCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border)),
      child: Column(
        children: [
          _CField(
            ctrl: numCtrl,
            label: 'Card number',
            hint: '0000  0000  0000  0000',
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            suffixIcon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _CField(
                ctrl: expiryCtrl,
                label: 'MM / YY',
                hint: '08 / 28',
                maxLength: 5,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CField(
                ctrl: cvvCtrl,
                label: 'CVV',
                hint: '···',
                maxLength: 3,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                obscureText: true,
                suffixIcon: Icons.help_outline_rounded,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _CField(
            ctrl: nameCtrl,
            label: 'Name on card',
            hint: 'As on card',
            keyboardType: TextInputType.name,
          ),
        ],
      ),
    );
  }
}

class _CField extends StatelessWidget {
  const _CField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
  });
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
                color: _C.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 16, fontWeight: FontWeight.w600, color: _C.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
                color: _C.muted.withValues(alpha: 0.6), fontSize: 16),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8F7F4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _C.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _C.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _C.ink, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 16, color: _C.muted)
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── Wallet Tab ───────────────────────────────────────────────────────────────

class _WalletTab extends StatelessWidget {
  const _WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    const wallets = [
      ('Paytm Wallet', Color(0xFF00BAF2), Icons.account_balance_wallet_rounded),
      ('Amazon Pay', Color(0xFFFF9900), Icons.shopping_bag_outlined),
      ('Airtel Money', Color(0xFFE40000), Icons.sim_card_outlined),
      ('Jio Money', Color(0xFF0066CC), Icons.monetization_on_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select wallet',
              style: _C.body(
                  color: _C.ink, size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...wallets.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border)),
                  child: Row(children: [
                    Icon(w.$3, color: w.$2, size: 24),
                    const SizedBox(width: 12),
                    Text(w.$1,
                        style: _C.body(
                            color: _C.ink, weight: FontWeight.w700)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: _C.muted, size: 18),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Success View ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.total,
    required this.eventName,
    required this.bookingId,
    required this.onContinue,
    required this.scaleAnim,
    super.key,
  });
  final double total;
  final String eventName;
  final String bookingId;
  final VoidCallback onContinue;
  final Animation<double> scaleAnim;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Checkmark
              ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                      color: Color(0xFFC8F135),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF0C1710), size: 60),
                ),
              ),
              const SizedBox(height: 36),

              Text('Payment Successful!',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),

              Text('Payment successful · ₹${total.round()}',
                  style: GoogleFonts.manrope(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('#$bookingId',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),

              const Spacer(),

              // Continue button
              GestureDetector(
                onTap: onContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC8F135),
                      borderRadius: BorderRadius.circular(18)),
                  child: Center(
                    child: Text('View My Orders',
                        style: GoogleFonts.manrope(
                            color: _C.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Auto-redirecting in 3 seconds…',
                  style: _C.body(size: 11,
                      color: Colors.white30,
                      weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Input formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
        text: s,
        selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '').replaceAll(' ', '');
    if (digits.isEmpty) return next;
    var out = digits.substring(0, digits.length.clamp(0, 2));
    if (digits.length > 2) out += ' / ${digits.substring(2, digits.length.clamp(2, 4))}';
    return TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: out.length));
  }
}
