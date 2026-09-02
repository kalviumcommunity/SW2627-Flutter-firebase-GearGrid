import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/booking_provider.dart';
import '../../state/auth_provider.dart';
import '../../services/functions_service.dart';

class BookingDetailsPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailsProvider(bookingId));
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: bookingAsync.when(
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          final role = roleAsync.value ?? 'client';
          final functions = FunctionsService();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client: ${booking.clientName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Status: ${booking.status}', style: const TextStyle(fontSize: 16)),
                Text('Phone: ${booking.contactPhone}'),
                Text('Event: ${booking.eventType ?? "N/A"}'),
                Text('Start: ${booking.startDateTime}'),
                Text('End: ${booking.endDateTime}'),
                
                const SizedBox(height: 20),
                const Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...booking.equipmentRequested.map((item) => ListTile(
                  title: Text(item.equipmentName),
                  subtitle: Text('Qty: ${item.quantity}'),
                )),

                const SizedBox(height: 20),
                // Role specific actions
                if (role == 'staff' || role == 'admin') ...[
                  if (booking.status == 'Requested') ...[
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await functions.confirmBooking(booking.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking Confirmed!'))
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'))
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Confirm Booking'),
                    ),
                  ],
                  if (['Requested', 'Confirmed'].contains(booking.status)) ...[
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await functions.cancelBooking(booking.id, 'Staff cancelled');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking Cancelled'))
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'))
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancel Booking'),
                    ),
                  ],
                ],
                
                if (role == 'warehouse') ...[
                  if (booking.status == 'Confirmed') ...[
                    ElevatedButton(
                      onPressed: () async {
                        await functions.dispatchBooking(booking.id);
                      },
                      child: const Text('Mark Dispatched'),
                    ),
                  ],
                  if (booking.status == 'Dispatched') ...[
                    ElevatedButton(
                      onPressed: () async {
                        await functions.returnBooking(booking.id);
                      },
                      child: const Text('Mark Returned'),
                    ),
                  ],
                ]
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
