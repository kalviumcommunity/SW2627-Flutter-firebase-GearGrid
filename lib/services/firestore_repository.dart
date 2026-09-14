import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_role.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/equipment.dart';

class BookingConflictException implements Exception {
  const BookingConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _equipment =>
      _firestore.collection('equipment');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reservationSlots =>
      _firestore.collection('reservationSlots');

  Stream<AppUser?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : AppUser.fromMap(snapshot.id, data);
    });
  }

  Future<void> ensureUserProfile(User user) async {
    final displayName = user.displayName?.trim();
    final userReference = _users.doc(user.uid);
    final existingProfile = await userReference.get();
    final commonFields = {
      'email': user.email ?? '',
      'displayName': displayName == null || displayName.isEmpty
          ? 'GearGrid client'
          : displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existingProfile.exists) {
      final updates = Map<String, dynamic>.from(commonFields);
      if (user.email == 'admin@geargrid.app') {
        updates['role'] = AppRole.admin.storageValue;
      }
      await userReference.update(updates);
      return;
    }

    await userReference.set({
      ...commonFields,
      'role': user.email == 'admin@geargrid.app' 
          ? AppRole.admin.storageValue 
          : AppRole.client.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Equipment>> watchEquipment() {
    return _equipment
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => Equipment.fromMap(document.id, document.data()),
              )
              .toList(),
        );
  }

  Stream<List<Booking>> watchBookings({required AppUser user}) {
    Query<Map<String, dynamic>> query = _bookings.orderBy('start');
    if (user.role != AppRole.admin) {
      query = query.where('clientId', isEqualTo: user.id);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => Booking.fromMap(document.id, document.data()))
          .toList(),
    );
  }

  Stream<Map<String, int>> watchReservedUnits({
    required DateTime start,
    required DateTime end,
  }) {
    return _reservationSlots
        .where('slotStart', isGreaterThanOrEqualTo: start)
        .where('slotStart', isLessThan: end)
        .snapshots()
        .map((snapshot) {
          final peakReservedUnits = <String, int>{};
          for (final document in snapshot.docs) {
            final data = document.data();
            final equipmentId = data['equipmentId'] as String?;
            final reservedUnits =
                (data['reservedUnits'] as num?)?.toInt() ?? 0;
            if (equipmentId == null) {
              continue;
            }
            final currentPeak = peakReservedUnits[equipmentId] ?? 0;
            if (reservedUnits > currentPeak) {
              peakReservedUnits[equipmentId] = reservedUnits;
            }
          }
          return peakReservedUnits;
        });
  }

  Future<void> createBooking(Booking booking) {
    return _bookings.doc(booking.id).set({
      ...booking.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveBooking(String bookingId) async {
    final bookingRef = _bookings.doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      if (bookingData == null) {
        throw const BookingConflictException('This booking no longer exists.');
      }

      final booking = Booking.fromMap(bookingSnapshot.id, bookingData);
      if (!booking.status.canBeApproved) {
        throw const BookingConflictException(
          'Only new paid orders can be confirmed.',
        );
      }

      final inventoryById = <String, Equipment>{};
      for (final equipmentId in booking.requestedUnits.keys) {
        final equipmentSnapshot = await transaction.get(
          _equipment.doc(equipmentId),
        );
        final equipmentData = equipmentSnapshot.data();
        if (equipmentData == null) {
          throw BookingConflictException(
            'An item in this request has been removed from inventory.',
          );
        }
        inventoryById[equipmentId] = Equipment.fromMap(
          equipmentSnapshot.id,
          equipmentData,
        );
      }

      final slotReferences =
          <String, DocumentReference<Map<String, dynamic>>>{};
      final slotSnapshots = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final equipmentId in booking.requestedUnits.keys) {
        for (final slotStart in _hourlySlots(booking.start, booking.end)) {
          final slotId = '${equipmentId}_${slotStart.millisecondsSinceEpoch}';
          final slotReference = _reservationSlots.doc(slotId);
          slotReferences[slotId] = slotReference;
          slotSnapshots[slotId] = await transaction.get(slotReference);
        }
      }

      for (final entry in booking.requestedUnits.entries) {
        final equipment = inventoryById[entry.key]!;
        for (final slotStart in _hourlySlots(booking.start, booking.end)) {
          final slotId = '${entry.key}_${slotStart.millisecondsSinceEpoch}';
          final reserved =
              (slotSnapshots[slotId]!.data()?['reservedUnits'] as num?)
                  ?.toInt() ??
              0;
          if (reserved + entry.value > equipment.totalUnits) {
            throw BookingConflictException(
              '${equipment.name} is no longer available for this event window.',
            );
          }
        }
      }

      for (final entry in booking.requestedUnits.entries) {
        for (final slotStart in _hourlySlots(booking.start, booking.end)) {
          final slotId = '${entry.key}_${slotStart.millisecondsSinceEpoch}';
          final existing = slotSnapshots[slotId]!.data();
          final reserved = (existing?['reservedUnits'] as num?)?.toInt() ?? 0;
          transaction.set(slotReferences[slotId]!, {
            'equipmentId': entry.key,
            'slotStart': slotStart,
            'reservedUnits': reserved + entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(bookingRef, {
        'status': BookingStatus.approved.name,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _bookings.doc(bookingId).update({'status': status.name});
  }

  Future<void> updateBooking(Booking booking) async {
    await _bookings.doc(booking.id).update(booking.toMap());
  }

  Future<void> saveEquipment(Equipment equipment) {
    return _equipment.doc(equipment.id).set({
      ...equipment.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteEquipment(String equipmentId) {
    return _equipment.doc(equipmentId).delete();
  }

  Future<void> updateEquipmentUnits(String equipmentId, int totalUnits) {
    return _equipment.doc(equipmentId).update({
      'totalUnits': totalUnits,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<DateTime> _hourlySlots(DateTime start, DateTime end) {
    final slots = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day, start.hour);
    while (current.isBefore(end)) {
      slots.add(current);
      current = current.add(const Duration(hours: 1));
    }
    return slots;
  }

  Future<Map<String, dynamic>> fetchBookingHistory({
    required int limit,
    dynamic startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _bookings
        .where('status', whereIn: ['completed', 'rejected'])
        .orderBy('start', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    final bookings = docs
        .map((document) => Booking.fromMap(document.id, document.data()))
        .toList();

    return {
      'bookings': bookings,
      'lastDoc': docs.isNotEmpty ? docs.last : null,
      'hasMore': docs.length == limit,
    };
  }
}
