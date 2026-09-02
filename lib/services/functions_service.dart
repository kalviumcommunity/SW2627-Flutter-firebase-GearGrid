import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<String?> createBookingRequest({
    required String clientName,
    required String contactPhone,
    String? eventType,
    String? location,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required List<Map<String, dynamic>> equipmentRequested,
  }) async {
    try {
      final callable = _functions.httpsCallable('createBookingRequest');
      final result = await callable.call({
        'clientName': clientName,
        'contactPhone': contactPhone,
        'eventType': eventType,
        'location': location,
        'startDateTime': startDateTime.millisecondsSinceEpoch,
        'endDateTime': endDateTime.millisecondsSinceEpoch,
        'equipmentRequested': equipmentRequested,
      });
      return result.data['bookingId'];
    } catch (e) {
      print('Error calling createBookingRequest: $e');
      rethrow;
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    try {
      final callable = _functions.httpsCallable('confirmBooking');
      await callable.call({'bookingId': bookingId});
    } catch (e) {
      print('Error calling confirmBooking: $e');
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelBooking');
      await callable.call({'bookingId': bookingId, 'reason': reason});
    } catch (e) {
      print('Error calling cancelBooking: $e');
      rethrow;
    }
  }

  Future<void> dispatchBooking(String bookingId) async {
    try {
      final callable = _functions.httpsCallable('dispatchBooking');
      await callable.call({'bookingId': bookingId});
    } catch (e) {
      print('Error calling dispatchBooking: $e');
      rethrow;
    }
  }

  Future<void> returnBooking(String bookingId) async {
    try {
      final callable = _functions.httpsCallable('returnBooking');
      await callable.call({'bookingId': bookingId});
    } catch (e) {
      print('Error calling returnBooking: $e');
      rethrow;
    }
  }
}
