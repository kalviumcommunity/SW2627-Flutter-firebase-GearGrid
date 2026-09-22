import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment.dart';
import '../theme/client_theme.dart';
import 'live_pulse_dot.dart';
import 'equipment_details_sheet.dart';

class EquipmentCatalogCard extends StatelessWidget {
  const EquipmentCatalogCard({
    required this.equipment,
    required this.available,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
    required this.animController,
    required this.index,
    super.key,
  });
  
  final Equipment equipment;
  final int available;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final AnimationController animController;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.07).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: animController,
      curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(animation),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            EquipmentDetailsSheet.show(context, equipment, available);
          },
          child: _CardBody(
            equipment: equipment,
            available: available,
            cartQty: cartQty,
            onAdd: onAdd,
            onRemove: onRemove,
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.equipment,
    required this.available,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
  });
  
  final Equipment equipment;
  final int available;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  String _formatPrice(double price) {
    if (price <= 0) return 'Price on request';
    final p = price.round();
    if (p >= 1000) return '₹${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}k / unit';
    return '₹$p / unit';
  }

  @override
  Widget build(BuildContext context) {
    final inCart = cartQty > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ClientTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: inCart ? ClientTheme.ink.withValues(alpha: 0.5) : ClientTheme.border,
          width: inCart ? 2.0 : 1.0,
        ),
        boxShadow: inCart
            ? [
                BoxShadow(
                    color: ClientTheme.ink.withValues(alpha: 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardImageZone(equipment: equipment, inCart: inCart),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.head(size: 15, color: ClientTheme.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equipment.powerProfile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.body(size: 10, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    _formatPrice(equipment.pricePerUnit),
                    style: GoogleFonts.spaceGrotesk(
                        color: ClientTheme.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AvailabilityBadge(available: available),
                      const Spacer(),
                      _QtyControl(
                        qty: cartQty,
                        enabled: available > 0,
                        onAdd: onAdd,
                        onRemove: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardImageZone extends StatelessWidget {
  const _CardImageZone({required this.equipment, required this.inCart});
  final Equipment equipment;
  final bool inCart;

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sound':
      case 'voice':
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
      case 'power':
        return Icons.bolt_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: equipment.accent.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: equipment.imageUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(
                    equipment.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        _categoryIcon(equipment.category),
                        size: 54,
                        color: ClientTheme.ink.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Icon(
                    _categoryIcon(equipment.category),
                    size: 54,
                    color: ClientTheme.ink.withValues(alpha: 0.65),
                  ),
                ),
        ),
        Positioned(
          left: 11,
          top: 11,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              equipment.category.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                  color: ClientTheme.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9),
            ),
          ),
        ),
        if (inCart)
          Positioned(
            right: 11,
            top: 11,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: ClientTheme.ink, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_rounded, color: ClientTheme.lime, size: 14),
            ),
          ),
      ],
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.qty,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });
  
  final int qty;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: qty == 0
          ? GestureDetector(
              key: const ValueKey('add'),
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onAdd();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: enabled ? ClientTheme.ink : const Color(0xFFECE9E0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'ADD',
                  style: GoogleFonts.spaceGrotesk(
                    color: enabled ? ClientTheme.lime : const Color(0xFFBBB8AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('stepper'),
              decoration: BoxDecoration(
                  color: ClientTheme.ink, borderRadius: BorderRadius.circular(11)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TinyBtn(icon: Icons.remove_rounded, onTap: onRemove),
                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Text(
                        '$qty',
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  _TinyBtn(icon: Icons.add_rounded, onTap: enabled ? onAdd : null),
                ],
              ),
            ),
    );
  }
}

class _TinyBtn extends StatelessWidget {
  const _TinyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 16, color: onTap == null ? Colors.white24 : ClientTheme.lime),
        ),
      );
}
