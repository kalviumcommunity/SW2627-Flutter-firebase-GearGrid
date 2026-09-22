import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../models/pay_method.dart';
import '../theme/client_theme.dart';
import 'card_payment_tab.dart';
import 'order_summary_card.dart';
import 'payment_method_tabs.dart';
import 'upi_payment_tab.dart';
import 'wallet_payment_tab.dart';

class PaymentForm extends StatelessWidget {
  const PaymentForm({
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
  final PayMethod method;
  final ValueChanged<PayMethod> onMethodChange;
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
      backgroundColor: ClientTheme.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: ClientTheme.surface,
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: ClientTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ClientTheme.border)),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: ClientTheme.ink),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Checkout',
                          style: ClientTheme.head(size: 20, color: ClientTheme.ink)),
                      Text('Pay ₹${totalAmount.round()} for $eventName',
                          style: ClientTheme.body(size: 11),
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

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderSummaryCard(
                      items: items,
                      quantities: quantities,
                      total: totalAmount),
                  const SizedBox(height: 22),

                  Text('Payment Method',
                      style: ClientTheme.head(size: 18, color: ClientTheme.ink)),
                  const SizedBox(height: 12),
                  PaymentMethodTabs(
                      selected: method, onSelect: onMethodChange),
                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: method == PayMethod.upi
                        ? UpiPaymentTab(
                            key: const ValueKey('upi'),
                            ctrl: upiCtrl,
                            selectedApp: selectedUpiApp,
                            onAppSelect: onUpiAppSelect,
                          )
                        : method == PayMethod.card
                            ? CardPaymentTab(
                                key: const ValueKey('card'),
                                numCtrl: cardNumCtrl,
                                expiryCtrl: expiryCtrl,
                                cvvCtrl: cvvCtrl,
                                nameCtrl: nameCtrl,
                              )
                            : const WalletPaymentTab(key: ValueKey('wallet')),
                  ),

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
                              style: ClientTheme.body(
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

      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          color: ClientTheme.surface,
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
                          ? ClientTheme.ink.withValues(alpha: 0.55)
                          : ClientTheme.ink,
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
                style: ClientTheme.body(size: 10, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
