import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pay_method.dart';
import '../theme/client_theme.dart';

class PaymentMethodTabs extends StatelessWidget {
  const PaymentMethodTabs({
    required this.selected,
    required this.onSelect,
    super.key,
  });
  
  final PayMethod selected;
  final ValueChanged<PayMethod> onSelect;

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
              active: selected == PayMethod.upi,
              onTap: () { HapticFeedback.selectionClick(); onSelect(PayMethod.upi); }),
          _Tab(
              label: 'Card',
              active: selected == PayMethod.card,
              onTap: () { HapticFeedback.selectionClick(); onSelect(PayMethod.card); }),
          _Tab(
              label: 'Wallet',
              active: selected == PayMethod.wallet,
              onTap: () { HapticFeedback.selectionClick(); onSelect(PayMethod.wallet); }),
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
            color: active ? ClientTheme.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.manrope(
                    color: active ? Colors.white : ClientTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
