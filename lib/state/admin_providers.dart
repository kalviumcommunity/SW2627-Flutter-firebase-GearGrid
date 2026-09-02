import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

// ── All bookings ──────────────────────────────────────────────────
final allBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(bookingServiceProvider).allBookingsStream();
});

// ── Pending (Requested) bookings ──────────────────────────────────
final pendingBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(bookingServiceProvider).bookingsByStatusStream('Requested');
});

// ── Dispatched bookings ───────────────────────────────────────────
final dispatchedBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(bookingServiceProvider).bookingsByStatusStream('Dispatched');
});

// ── Confirmed bookings ────────────────────────────────────────────
final confirmedBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(bookingServiceProvider).bookingsByStatusStream('Confirmed');
});
