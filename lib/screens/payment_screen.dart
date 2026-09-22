import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/equipment.dart';
import '../models/pay_method.dart';
import '../services/firestore_repository.dart';
import '../theme/client_theme.dart';
import '../widgets/payment_form.dart';
import '../widgets/payment_success_view.dart';

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
  PayMethod _method = PayMethod.upi;
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
    if (_method == PayMethod.upi &&
        _selectedUpiApp.isEmpty &&
        _upiCtrl.text.trim().isEmpty) {
      _setError('Choose a UPI app or enter your UPI ID.');
      return;
    }
    if (_method == PayMethod.card) {
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
      PayMethod.upi => _selectedUpiApp.isNotEmpty ? _selectedUpiApp : 'UPI',
      PayMethod.card => 'Card',
      PayMethod.wallet => 'Wallet',
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
      backgroundColor: ClientTheme.surface,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _phase == _phaseSuccess
            ? PaymentSuccessView(
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
                    color: ClientTheme.ink,
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
                : PaymentForm(
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
