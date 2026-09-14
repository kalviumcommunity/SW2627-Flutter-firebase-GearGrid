enum BookingStatus {
  paid,       // Client paid → enters admin queue
  pending,    // Legacy / backwards compat
  approved,   // Admin confirmed
  dispatched, // Equipment sent out
  completed,  // Event done
  rejected;   // Cancelled / rejected

  String get label => switch (this) {
        BookingStatus.paid => 'Order Received',
        BookingStatus.pending => 'Pending',
        BookingStatus.approved => 'Confirmed',
        BookingStatus.dispatched => 'Dispatched',
        BookingStatus.completed => 'Completed',
        BookingStatus.rejected => 'Cancelled',
      };

  /// Admin can approve bookings in these states.
  bool get canBeApproved =>
      this == BookingStatus.paid || this == BookingStatus.pending;
}

class Booking {
  const Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.eventName,
    required this.venue,
    required this.start,
    required this.end,
    required this.status,
    required this.requestedUnits,
    this.subtotal = 0.0,
    this.platformFee = 99.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.paymentId,
    this.paymentMethod,
    this.mapsLink,
    this.driverName,
    this.vehicleDetails,
    this.deliveryEta,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String eventName;
  final String venue;
  final DateTime start;
  final DateTime end;
  final BookingStatus status;
  final Map<String, int> requestedUnits;

  /// Financial fields — populated at checkout.
  final double subtotal;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final String? paymentId;
  final String? paymentMethod;
  
  /// Dispatch & Delivery fields
  final String? mapsLink;
  final String? driverName;
  final String? vehicleDetails;
  final DateTime? deliveryEta;

  Booking copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? eventName,
    String? venue,
    DateTime? start,
    DateTime? end,
    BookingStatus? status,
    Map<String, int>? requestedUnits,
    double? subtotal,
    double? platformFee,
    double? taxAmount,
    double? totalAmount,
    String? paymentId,
    String? paymentMethod,
    String? mapsLink,
    String? driverName,
    String? vehicleDetails,
    DateTime? deliveryEta,
  }) {
    return Booking(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      eventName: eventName ?? this.eventName,
      venue: venue ?? this.venue,
      start: start ?? this.start,
      end: end ?? this.end,
      status: status ?? this.status,
      requestedUnits: requestedUnits ?? this.requestedUnits,
      subtotal: subtotal ?? this.subtotal,
      platformFee: platformFee ?? this.platformFee,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mapsLink: mapsLink ?? this.mapsLink,
      driverName: driverName ?? this.driverName,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      deliveryEta: deliveryEta ?? this.deliveryEta,
    );
  }

  bool overlaps(DateTime otherStart, DateTime otherEnd) {
    return start.isBefore(otherEnd) && end.isAfter(otherStart);
  }

  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    final requestedUnits = <String, int>{};
    final rawUnits = data['requestedUnits'] as Map<String, dynamic>? ?? {};
    for (final entry in rawUnits.entries) {
      if (entry.value is num) {
        requestedUnits[entry.key] = (entry.value as num).toInt();
      }
    }

    return Booking(
      id: id,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? 'Client',
      eventName: data['eventName'] as String? ?? 'Untitled event',
      venue: data['venue'] as String? ?? '',
      start: (data['start'] as dynamic).toDate() as DateTime,
      end: (data['end'] as dynamic).toDate() as DateTime,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      requestedUnits: requestedUnits,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      platformFee: (data['platformFee'] as num?)?.toDouble() ?? 99.0,
      taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentId: data['paymentId'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      mapsLink: data['mapsLink'] as String?,
      driverName: data['driverName'] as String?,
      vehicleDetails: data['vehicleDetails'] as String?,
      deliveryEta: data['deliveryEta'] != null ? (data['deliveryEta'] as dynamic).toDate() as DateTime : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'eventName': eventName,
      'venue': venue,
      'start': start,
      'end': end,
      'status': status.name,
      'requestedUnits': requestedUnits,
      'subtotal': subtotal,
      'platformFee': platformFee,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      if (paymentId != null) 'paymentId': paymentId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (mapsLink != null) 'mapsLink': mapsLink,
      if (driverName != null) 'driverName': driverName,
      if (vehicleDetails != null) 'vehicleDetails': vehicleDetails,
      if (deliveryEta != null) 'deliveryEta': deliveryEta,
    };
  }
}
