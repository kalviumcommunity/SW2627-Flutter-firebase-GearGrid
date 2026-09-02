import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Equipment Queries
  Stream<List<Equipment>> streamEquipment() {
    return _db
        .collection('equipment')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList());
  }

  // Bookings Queries
  Stream<List<Booking>> streamClientBookings(String clientId) {
    return _db
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> streamPendingBookings() {
    return _db
        .collection('bookings')
        .where('status', isEqualTo: 'Requested')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<List<Booking>> streamConfirmedBookings() {
    return _db
        .collection('bookings')
        .where('status', isEqualTo: 'Confirmed')
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }
  
  Stream<List<Booking>> streamDispatchedBookings() {
    return _db
        .collection('bookings')
        .where('status', isEqualTo: 'Dispatched')
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  Stream<Booking?> streamBookingDetails(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    });
  }
}
