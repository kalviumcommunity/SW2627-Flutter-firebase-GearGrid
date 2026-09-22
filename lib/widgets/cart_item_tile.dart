import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/client_theme.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });
  
  final Equipment item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  IconData _catIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'sound':
      case 'audio':
        return Icons.speaker_group_rounded;
      case 'lighting':
      case 'lights':
        return Icons.lightbulb_outline_rounded;
      case 'visual':
      case 'visuals':
      case 'screen':
        return Icons.tv_rounded;
      case 'furniture':
        return Icons.weekend_outlined;
      case 'staging':
      case 'stage':
        return Icons.theater_comedy_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.pricePerUnit * qty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientTheme.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Icon(_catIcon(item.category),
                    size: 22, color: ClientTheme.ink)),
          ),
          const SizedBox(width: 14),

          // Name + price per unit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: ClientTheme.body(
                        color: ClientTheme.ink,
                        size: 14,
                        weight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    item.pricePerUnit > 0
                        ? '₹${item.pricePerUnit.round()} / unit'
                        : item.category,
                    style: ClientTheme.body(size: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Stepper + subtotal column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lineTotal > 0)
                Text('₹${lineTotal.round()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: ClientTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _Stepper(qty: qty, onAdd: onAdd, onRemove: onRemove),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.qty, required this.onAdd, required this.onRemove});
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ClientTheme.ink, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
              icon: qty == 1 ? Icons.delete_rounded : Icons.remove_rounded,
              onTap: onRemove),
          SizedBox(
            width: 26,
            child: Center(
              child: Text('$qty',
                  style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onAdd),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 15, color: ClientTheme.lime),
        ),
      );
}
