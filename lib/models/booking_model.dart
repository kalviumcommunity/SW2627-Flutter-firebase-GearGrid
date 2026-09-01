import 'package:cloud_firestore/cloud_firestore.dart';

class BookingItem {
  final String equipmentId;
  final String name;
  final String category;
  final int quantity;

  BookingItem({
    required this.equipmentId,
    required this.name,
    required this.category,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'equipmentId': equipmentId,
        'name': name,
        'category': category,
        'quantity': quantity,
      };

  factory BookingItem.fromMap(Map<String, dynamic> map) => BookingItem(
        equipmentId: map['equipmentId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
}

class BookingModel {
  final String id;
  final String clientId;
  final String clientEmail;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;

  /// One of: Requested | Confirmed | Dispatched | Returned | Cancelled
  final String status;

  final List<BookingItem> items;
  final int totalItems;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientEmail,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.items,
    required this.totalItems,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'clientEmail': clientEmail,
        'eventName': eventName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': status,
        'items': items.map((e) => e.toMap()).toList(),
        'totalItems': totalItems,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime toDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return DateTime.now();
    }

    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => BookingItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return BookingModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      clientEmail: data['clientEmail'] as String? ?? '',
      eventName: data['eventName'] as String? ?? 'Unnamed Event',
      startDate: toDate(data['startDate']),
      endDate: toDate(data['endDate']),
      status: data['status'] as String? ?? 'Requested',
      items: items,
      totalItems: (data['totalItems'] as num?)?.toInt() ?? items.length,
      createdAt: toDate(data['createdAt']),
    );
  }

  /// Human-friendly date range label e.g. "Jun 15 – Jun 17"
  String get dateRangeLabel {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final s = '${months[startDate.month - 1]} ${startDate.day}';
    final e = '${months[endDate.month - 1]} ${endDate.day}';
    return '$s – $e';
  }

  /// Display-friendly time-ago label
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
