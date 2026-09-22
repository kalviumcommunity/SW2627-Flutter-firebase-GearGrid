import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/client_theme.dart';

class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    required this.subtotal,
    required this.platformFee,
    required this.gst,
    required this.total,
    super.key,
  });
  
  final double subtotal;
  final double platformFee;
  final double gst;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ClientTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClientTheme.border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Price Breakdown',
                style: ClientTheme.head(size: 16, color: ClientTheme.ink)),
          ),
          const SizedBox(height: 12),
          _Row('Equipment subtotal', '₹${subtotal.round()}'),
          _Row('Platform fee', '₹${platformFee.round()}',
              note: 'One-time service charge'),
          _Row('GST (18%)', '₹${gst.round()}',
              note: 'On subtotal + platform fee'),
          Divider(
              color: ClientTheme.border.withValues(alpha: 0.7),
              height: 24,
              indent: 16,
              endIndent: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ClientTheme.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text('Total',
                    style: GoogleFonts.spaceGrotesk(
                        color: ClientTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₹${total.round()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: ClientTheme.lime,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.note});
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ClientTheme.body(color: ClientTheme.ink, weight: FontWeight.w600)),
                if (note != null) Text(note!, style: ClientTheme.body(size: 10)),
              ],
            ),
          ),
          Text(value,
              style: ClientTheme.body(
                  color: ClientTheme.ink,
                  size: 14,
                  weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
