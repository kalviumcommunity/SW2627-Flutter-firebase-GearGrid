import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/client_theme.dart';

class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({
    required this.itemCount,
    required this.itemKinds,
    required this.cartTotal,
    required this.canRequest,
    required this.onPressed,
    super.key,
  });
  
  final int itemCount;
  final int itemKinds;
  final double cartTotal;
  final bool canRequest;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientTheme.ink,
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: ClientTheme.accent,
                borderRadius: BorderRadius.circular(15)),
            child: Center(
              child: Text(
                '$itemCount',
                style: GoogleFonts.spaceGrotesk(
                    color: ClientTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemKinds equipment type${itemKinds == 1 ? '' : 's'}',
                  style: ClientTheme.body(color: Colors.white, weight: FontWeight.w800),
                ),
                Text(
                  canRequest
                      ? (cartTotal > 0 ? '₹${cartTotal.round()} · Ready to book' : 'Ready to review')
                      : 'Some items need attention',
                  style: ClientTheme.body(
                      color: canRequest ? const Color(0xFF9DD97A) : const Color(0xFFFFAA88),
                      size: 11,
                      weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                  color: ClientTheme.lime,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Cart',
                      style: GoogleFonts.manrope(
                          color: ClientTheme.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: ClientTheme.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
