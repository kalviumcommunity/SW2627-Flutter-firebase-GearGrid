import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gear_grid/models/booking.dart';
import 'package:gear_grid/models/equipment.dart';
import 'package:gear_grid/services/booking_engine.dart';

void main() {
  test('blocks an overlapping approval that exceeds equipment capacity', () {
    const inventory = [
      Equipment(
        id: 'wireless_mics',
        name: 'Wireless Mic Kit',
        category: 'Voice',
        description: 'Dual channel microphones',
        powerProfile: 'Battery backed',
        totalUnits: 8,
        accent: Color(0xFF52D1FF),
      ),
    ];
    final start = DateTime(2026, 10, 1, 18);
    final bookings = [
      Booking(
        id: 'existing-booking',
        clientId: 'client-a',
        clientName: 'Prism Weddings',
        eventName: 'Reception',
        venue: 'Lakeview Pavilion',
        start: start,
        end: start.add(const Duration(hours: 4)),
        status: BookingStatus.approved,
        requestedUnits: const {'wireless_mics': 6},
      ),
    ];

    final result = BookingEngine.evaluate(
      inventory: inventory,
      bookings: bookings,
      start: start.add(const Duration(hours: 1)),
      end: start.add(const Duration(hours: 3)),
      request: const {'wireless_mics': 3},
    );

    expect(result.canApprove, isFalse);
    expect(result.lines.single.remainingAfterApproval, -1);
  });
}
