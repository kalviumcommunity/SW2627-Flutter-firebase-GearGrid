import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/client_theme.dart';
import 'live_pulse_dot.dart';

class EquipmentDetailsSheet {
  static IconData _catIcon(String cat) {
    final l = cat.toLowerCase();
    if (l.contains('light')) return Icons.lightbulb_outline_rounded;
    if (l.contains('sound') || l.contains('audio')) return Icons.speaker_group_rounded;
    if (l.contains('visual')) return Icons.tv_rounded;
    if (l.contains('furn')) return Icons.weekend_outlined;
    if (l.contains('power')) return Icons.bolt_rounded;
    return Icons.category_outlined;
  }

  static String _formatPrice(double price) {
    if (price <= 0) return 'Price on request';
    final p = price.round();
    if (p >= 1000) return '₹${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}k / unit';
    return '₹$p / unit';
  }

  static void show(BuildContext context, Equipment equipment, int available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ClientTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.paddingOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ClientTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(_catIcon(equipment.category), color: equipment.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(equipment.name, style: ClientTheme.head(size: 20)),
                      Text(equipment.powerProfile, style: ClientTheme.body(size: 13, color: ClientTheme.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('DESCRIPTION',
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: ClientTheme.muted)),
            const SizedBox(height: 8),
            Text(equipment.description, style: ClientTheme.body(size: 14, color: ClientTheme.ink, weight: FontWeight.w500)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price', style: ClientTheme.body(size: 14)),
                Text(_formatPrice(equipment.pricePerUnit), style: ClientTheme.head(size: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available units', style: ClientTheme.body(size: 14)),
                AvailabilityBadge(available: available),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
