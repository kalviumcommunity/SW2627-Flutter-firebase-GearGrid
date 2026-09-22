import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

class CardPaymentTab extends StatelessWidget {
  const CardPaymentTab({
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
          color: ClientTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClientTheme.border)),
      child: Column(
        children: [
          _CreditCardField(
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
              child: _CreditCardField(
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
              child: _CreditCardField(
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
          _CreditCardField(
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

class _CreditCardField extends StatelessWidget {
  const _CreditCardField({
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
                color: ClientTheme.muted,
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
              fontSize: 16, fontWeight: FontWeight.w600, color: ClientTheme.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
                color: ClientTheme.muted.withValues(alpha: 0.6), fontSize: 16),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8F7F4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ClientTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ClientTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ClientTheme.ink, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, size: 16, color: ClientTheme.muted)
                : null,
          ),
        ),
      ],
    );
  }
}

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
    if (digits.length > 2) {
      out += ' / ${digits.substring(2, digits.length.clamp(2, 4))}';
    }
    return TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: out.length));
  }
}
