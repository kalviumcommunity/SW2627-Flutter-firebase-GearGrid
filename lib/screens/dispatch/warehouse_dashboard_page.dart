import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/booking_provider.dart';
import '../booking/booking_details_page.dart';

class WarehouseDashboardPage extends ConsumerWidget {
  const WarehouseDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmedBookings = ref.watch(confirmedBookingsProvider);
    final dispatchedBookings = ref.watch(dispatchedBookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warehouse Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF16845F),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'To Dispatch'),
              Tab(text: 'To Return'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(confirmedBookings),
            _buildList(dispatchedBookings),
          ],
        ),
      ),
    );
  }

  Widget _buildList(AsyncValue bookingsAsync) {
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
              subtitle: Text('${booking.startDateTime.toLocal()}'),
              trailing: const Icon(Icons.local_shipping),
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
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
