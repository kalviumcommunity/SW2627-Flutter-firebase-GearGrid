import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

const _upiApps = [
  ('GPay', Color(0xFF4285F4), Icons.g_mobiledata_rounded),
  ('PhonePe', Color(0xFF5F259F), Icons.phone_android_rounded),
  ('Paytm', Color(0xFF00BAF2), Icons.account_balance_wallet_rounded),
  ('BHIM', Color(0xFF003087), Icons.payment_rounded),
];

class UpiPaymentTab extends StatelessWidget {
  const UpiPaymentTab({
    required this.ctrl,
    required this.selectedApp,
    required this.onAppSelect,
    super.key,
  });
  
  final TextEditingController ctrl;
  final String selectedApp;
  final ValueChanged<String> onAppSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: ClientTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClientTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay using UPI app',
              style: ClientTheme.body(
                  color: ClientTheme.ink, size: 13, weight: FontWeight.w800)),
          const SizedBox(height: 14),

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
                          color: isSelected ? app.$2 : ClientTheme.border,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(app.$3, color: app.$2, size: 26),
                        const SizedBox(height: 4),
                        Text(app.$1,
                            style: GoogleFonts.manrope(
                                color: ClientTheme.ink,
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
                color: ClientTheme.ink),
            decoration: InputDecoration(
              hintText: 'yourname@bank',
              hintStyle: GoogleFonts.manrope(
                  color: ClientTheme.muted, fontSize: 13),
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
                  borderSide: const BorderSide(color: ClientTheme.ink, width: 1.5)),
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
