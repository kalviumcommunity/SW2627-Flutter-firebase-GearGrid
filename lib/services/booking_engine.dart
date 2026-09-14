import '../models/booking.dart';
import '../models/equipment.dart';

class AvailabilityLine {
  const AvailabilityLine({
    required this.equipment,
    required this.requestedUnits,
    required this.reservedUnits,
  });

  final Equipment equipment;
  final int requestedUnits;
  final int reservedUnits;

  int get availableUnits => equipment.totalUnits - reservedUnits;

  int get remainingAfterApproval => availableUnits - requestedUnits;

  bool get hasConflict => remainingAfterApproval < 0;
}

class AvailabilityCheckResult {
  const AvailabilityCheckResult({
    required this.canApprove,
    required this.lines,
  });

  final bool canApprove;
  final List<AvailabilityLine> lines;
}

class BookingEngine {
  static AvailabilityCheckResult evaluate({
    required List<Equipment> inventory,
    required List<Booking> bookings,
    required DateTime start,
    required DateTime end,
    required Map<String, int> request,
    String? ignoreBookingId,
  }) {
    final lines = <AvailabilityLine>[];

    for (final entry in request.entries.where((item) => item.value > 0)) {
      final equipment = inventory.firstWhere((item) => item.id == entry.key);
      final reservedUnits = bookings
          .where(
            (booking) =>
                booking.id != ignoreBookingId &&
                booking.overlaps(start, end) &&
                (booking.status == BookingStatus.approved ||
                    booking.status == BookingStatus.dispatched),
          )
          .fold<int>(
            0,
            (sum, booking) => sum + (booking.requestedUnits[equipment.id] ?? 0),
          );

      lines.add(
        AvailabilityLine(
          equipment: equipment,
          requestedUnits: entry.value,
          reservedUnits: reservedUnits,
        ),
      );
    }

    return AvailabilityCheckResult(
      canApprove: lines.isNotEmpty && lines.every((line) => !line.hasConflict),
      lines: lines,
    );
  }
}
