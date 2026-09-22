import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../theme/client_theme.dart';

class StoreHeroBanner extends StatelessWidget {
  const StoreHeroBanner({
    required this.user,
    required this.compact,
    required this.cartCount,
    required this.cartTotal,
    super.key,
  });
  
  final AppUser user;
  final bool compact;
  final int cartCount;
  final double cartTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: ClientTheme.ink, borderRadius: BorderRadius.circular(28)),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _copy(),
              const SizedBox(height: 20),
              _badge()
            ])
          : Row(children: [
              Expanded(child: _copy()),
              const SizedBox(width: 24),
              _badge()
            ]),
    );
  }

  Widget _copy() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.displayName.split(' ').first}\'s\nevent, properly stocked.',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 30,
                height: 1.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4),
          ),
          const SizedBox(height: 10),
          Text(
            'Add what you need. We keep the warehouse count in sync while you build.',
            style: ClientTheme.body(color: const Color(0xFFB0BDB0)),
          ),
        ],
      );

  Widget _badge() => Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF243328),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: ClientTheme.lime, size: 22),
            const SizedBox(height: 16),
            Text('$cartCount',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700)),
            Text('items in list',
                style: ClientTheme.body(
                    color: const Color(0xFF8EA18E), size: 11)),
            if (cartTotal > 0) ...[
              const SizedBox(height: 6),
              Text(
                '₹${cartTotal.round()}',
                style: GoogleFonts.spaceGrotesk(
                    color: ClientTheme.lime,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );
}
