import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/client_theme.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    required this.items,
    required this.quantities,
    required this.total,
    super.key,
  });
  
  final List<Equipment> items;
  final Map<String, int> quantities;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: ClientTheme.ink,
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
                    style: ClientTheme.body(
                        color: Colors.white, weight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('  ×$qty',
                    style: ClientTheme.body(
                        color: const Color(0xFF8A9489),
                        size: 12)),
                const Spacer(),
                if (lineTotal > 0)
                  Text('₹${lineTotal.round()}',
                      style: ClientTheme.body(
                          color: Colors.white,
                          size: 13,
                          weight: FontWeight.w700)),
              ]),
            );
          }),
          const Divider(color: Colors.white12, height: 20),
          Row(children: [
            Text('Total to pay', style: ClientTheme.body(color: Colors.white70, size: 12)),
            const Spacer(),
            Text('₹${total.round()}',
                style: GoogleFonts.spaceGrotesk(
                    color: ClientTheme.lime,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}
