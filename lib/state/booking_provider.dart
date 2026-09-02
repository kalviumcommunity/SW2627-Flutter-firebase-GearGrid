import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import 'equipment_provider.dart';
import 'auth_provider.dart';

final clientBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamClientBookings(user.uid);
});

final pendingBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamPendingBookings();
});

final confirmedBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamConfirmedBookings();
});

final dispatchedBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamDispatchedBookings();
});

final bookingDetailsProvider = StreamProvider.family<Booking?, String>((ref, bookingId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamBookingDetails(bookingId);
});
