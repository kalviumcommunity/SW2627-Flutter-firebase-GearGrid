import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(FirebaseFirestore.instance);
});

class BookingService {
  final FirebaseFirestore _db;
  BookingService(this._db);

  CollectionReference get _col => _db.collection('bookings');

  // ── CREATE ──────────────────────────────────────────────────────
  Future<String> createBooking(BookingModel booking) async {
    final ref = await _col.add(booking.toMap());
    return ref.id;
  }

  // ── READ: single booking ─────────────────────────────────────────
  Future<BookingModel?> getBooking(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromFirestore(doc);
  }

  // ── UPDATE STATUS ────────────────────────────────────────────────
  Future<void> updateStatus(String bookingId, String newStatus) async {
    await _col.doc(bookingId).update({'status': newStatus});
  }

  // ── STREAMS ───────────────────────────────────────────────────────

  /// All bookings ordered by newest first (admin – full view)
  Stream<List<BookingModel>> allBookingsStream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(BookingModel.fromFirestore).toList());
  }

  /// Bookings filtered by status
  Stream<List<BookingModel>> bookingsByStatusStream(String status) {
    return _col
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(BookingModel.fromFirestore).toList());
  }

  /// Client's own bookings
  Stream<List<BookingModel>> clientBookingsStream(String clientId) {
    return _col
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(BookingModel.fromFirestore).toList());
  }
}
