import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/booking_provider.dart';
import '../../state/auth_provider.dart';
import 'booking_details_page.dart';

class BookingListPage extends ConsumerWidget {
  const BookingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: roleAsync.when(
        data: (role) {
          if (role == 'client') {
            return _buildBookingList(ref, clientBookingsProvider);
          } else {
            // Staff/Admin can see confirmed bookings for simplicity here, or all
            // You can add tabs for Pending, Confirmed, etc.
            return _buildBookingList(ref, confirmedBookingsProvider);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBookingList(WidgetRef ref, provider) {
    final bookingsAsync = ref.watch(provider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return ListTile(
              title: Text(booking.clientName),
              subtitle: Text('${booking.status} - ${booking.equipmentIds.length} items'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailsPage(bookingId: booking.id),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading bookings: $e')),
    );
  }
}
