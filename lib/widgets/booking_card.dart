import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/equipment.dart';
import '../theme/admin_theme.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.booking,
    required this.inventory,
    required this.actions,
    super.key,
  });

  final Booking booking;
  final List<Equipment> inventory;
  final List<Widget> actions;

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min $suffix';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.eventName,
                  style: AdminTheme.brand(size: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_formatDate(booking.start), style: AdminTheme.body(size: 12, color: AdminTheme.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AdminTheme.muted),
              const SizedBox(width: 4),
              Text(booking.clientName, style: AdminTheme.body(size: 13, color: AdminTheme.muted)),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 14, color: AdminTheme.muted),
              const SizedBox(width: 4),
              Expanded(child: Text(booking.venue, style: AdminTheme.body(size: 13, color: AdminTheme.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 16),
          Text('EQUIPMENT REQUIRED', style: AdminTheme.body(size: 11, color: AdminTheme.muted, weight: FontWeight.w800).copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...booking.requestedUnits.entries.map((e) {
            final eq = inventory.cast<Equipment?>().firstWhere((i) => i?.id == e.key, orElse: () => null);
            final name = eq?.name ?? e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AdminTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('x${e.value}', style: AdminTheme.body(size: 11, color: AdminTheme.ink, weight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: AdminTheme.body(color: AdminTheme.ink, weight: FontWeight.w600))),
                ],
              ),
            );
          }),
          if (booking.driverName != null || booking.vehicleDetails != null || booking.mapsLink != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AdminTheme.border, height: 1),
            const SizedBox(height: 16),
            Text('DISPATCH DETAILS', style: AdminTheme.body(size: 11, color: AdminTheme.muted, weight: FontWeight.w800).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 12),
            if (booking.driverName != null) 
              _DispatchRow(icon: Icons.badge_outlined, text: booking.driverName!),
            if (booking.vehicleDetails != null) 
              _DispatchRow(icon: Icons.directions_car_outlined, text: booking.vehicleDetails!),
            if (booking.deliveryEta != null) 
              _DispatchRow(icon: Icons.access_time, text: 'ETA: ${_formatTime(booking.deliveryEta!)}'),
            if (booking.mapsLink != null) 
              _DispatchRow(icon: Icons.map_outlined, text: 'View on Maps', isLink: true),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _DispatchRow extends StatelessWidget {
  const _DispatchRow({required this.icon, required this.text, this.isLink = false});
  final IconData icon;
  final String text;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isLink ? AdminTheme.accent : AdminTheme.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AdminTheme.body(color: isLink ? AdminTheme.accent : AdminTheme.ink, weight: isLink ? FontWeight.w700 : FontWeight.w600))),
        ],
      ),
    );
  }
}
