import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/equipment.dart';

class DemoRepository {
  static List<Equipment> equipmentCatalog() {
    return const [
      Equipment(
        id: 'sound_line_array',
        name: 'Titan Line Array',
        category: 'Sound',
        description:
            'Concert-grade front-of-house system for outdoor or ballroom events.',
        powerProfile: '4 stacks / 12 kW rig',
        totalUnits: 4,
        accent: Color(0xFF52D1FF),
      ),
      Equipment(
        id: 'wireless_mics',
        name: 'Wireless Mic Kit',
        category: 'Voice',
        description:
            'Dual-channel handheld kits for panels, anchors, and wedding hosts.',
        powerProfile: 'Battery backed / low latency',
        totalUnits: 18,
        accent: Color(0xFFFFB44F),
      ),
      Equipment(
        id: 'moving_heads',
        name: 'Aurora Moving Heads',
        category: 'Lighting',
        description:
            'Sharp beam fixtures with color-wheel scenes for stage reveals.',
        powerProfile: '16 fixtures / DMX ready',
        totalUnits: 16,
        accent: Color(0xFFFF6B6B),
      ),
      Equipment(
        id: 'led_walls',
        name: 'Nova LED Wall Panels',
        category: 'Visual',
        description:
            'High-brightness modular panels for backdrops and brand moments.',
        powerProfile: '48 panels / pixel mapped',
        totalUnits: 48,
        accent: Color(0xFF97F3B0),
      ),
      Equipment(
        id: 'cocktail_tables',
        name: 'Cocktail Tables',
        category: 'Furniture',
        description:
            'Minimal event tables that work for receptions and corporate mixers.',
        powerProfile: 'Round high-top collection',
        totalUnits: 32,
        accent: Color(0xFFEAD9A7),
      ),
      Equipment(
        id: 'lounge_sofas',
        name: 'Lounge Sofa Pods',
        category: 'Furniture',
        description:
            'Modular sofa islands for VIP corners, bridal lounges, and green rooms.',
        powerProfile: '6 modular pods',
        totalUnits: 6,
        accent: Color(0xFFC7A6FF),
      ),
    ];
  }

  static List<Booking> seedBookings() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);
    final dayAfter = DateTime(now.year, now.month, now.day + 2, 16);
    final thirdDay = DateTime(now.year, now.month, now.day + 3, 11);

    return [
      Booking(
        id: 'bk-1001',
        clientId: 'demo-aarav',
        clientName: 'Aarav Event Co.',
        eventName: 'Skyline Sangeet',
        venue: 'Grand Meridian Rooftop',
        start: tomorrow,
        end: tomorrow.add(const Duration(hours: 5)),
        status: BookingStatus.approved,
        requestedUnits: const {
          'sound_line_array': 2,
          'wireless_mics': 6,
          'moving_heads': 8,
          'cocktail_tables': 12,
        },
      ),
      Booking(
        id: 'bk-1002',
        clientId: 'demo-prism',
        clientName: 'Prism Weddings',
        eventName: 'Crystal Aisle Reception',
        venue: 'Lakeview Pavilion',
        start: dayAfter,
        end: dayAfter.add(const Duration(hours: 6)),
        status: BookingStatus.dispatched,
        requestedUnits: const {
          'led_walls': 20,
          'moving_heads': 6,
          'lounge_sofas': 2,
        },
      ),
      Booking(
        id: 'bk-1003',
        clientId: 'demo-aarav',
        clientName: 'Aarav Event Co.',
        eventName: 'Founder Townhall',
        venue: 'Atlas Convention Hall',
        start: thirdDay,
        end: thirdDay.add(const Duration(hours: 4)),
        status: BookingStatus.pending,
        requestedUnits: const {
          'wireless_mics': 4,
          'led_walls': 12,
          'cocktail_tables': 8,
        },
      ),
      Booking(
        id: 'bk-1004',
        clientId: 'demo-northlight',
        clientName: 'Northlight Brands',
        eventName: 'Product Reveal',
        venue: 'Studio 18',
        start: DateTime(now.year, now.month, now.day - 1, 17),
        end: DateTime(now.year, now.month, now.day - 1, 22),
        status: BookingStatus.completed,
        requestedUnits: const {
          'sound_line_array': 1,
          'moving_heads': 4,
          'led_walls': 8,
        },
      ),
    ];
  }
}
