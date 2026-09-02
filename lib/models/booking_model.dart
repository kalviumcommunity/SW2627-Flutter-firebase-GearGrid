import 'package:cloud_firestore/cloud_firestore.dart';

class BookingItem {
  final String equipmentId;
  final String equipmentName;
  final String category;
  final int quantity;
  
  BookingItem({
    required this.equipmentId,
    required this.equipmentName,
    required this.category,
    required this.quantity,
  });

  factory BookingItem.fromMap(Map<String, dynamic> data) {
    return BookingItem(
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['name'] ?? data['equipmentName'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'name': equipmentName,
      'category': category,
      'quantity': quantity,
    };
  }
}

class BookingHistoryEntry {
  final String action;
  final String byUserId;
  final String byRole;
  final DateTime timestamp;
  final String? note;

  BookingHistoryEntry({
    required this.action,
    required this.byUserId,
    required this.byRole,
    required this.timestamp,
    this.note,
  });

  factory BookingHistoryEntry.fromMap(Map<String, dynamic> data) {
    return BookingHistoryEntry(
      action: data['action'] ?? '',
      byUserId: data['byUserId'] ?? '',
      byRole: data['byRole'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      note: data['note'],
    );
  }
}

class Booking {
  final String id;
  final String clientName;
  final String contactPhone;
  final String? eventType;
  final String? location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<String> equipmentIds;
  final List<BookingItem> equipmentRequested;
  final String status;
  final String createdBy;
  final String createdByRole;
  final DateTime createdAt;
  final List<BookingHistoryEntry> history;

  Booking({
    required this.id,
    required this.clientName,
    required this.contactPhone,
    this.eventType,
    this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.equipmentIds,
    required this.equipmentRequested,
    required this.status,
    required this.createdBy,
    required this.createdByRole,
    required this.createdAt,
    required this.history,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      clientName: data['clientName'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      eventType: data['eventType'],
      location: data['location'],
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      equipmentIds: List<String>.from(data['equipmentIds'] ?? []),
      equipmentRequested: (data['equipmentRequested'] as List<dynamic>?)
              ?.map((e) => BookingItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: data['status'] ?? 'Requested',
      createdBy: data['createdBy'] ?? '',
      createdByRole: data['createdByRole'] ?? 'client',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      history: (data['history'] as List<dynamic>?)
              ?.map((e) => BookingHistoryEntry.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
