import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../state/admin_providers.dart';
import 'booking_detail_page.dart';

class PendingRequestsPage extends ConsumerStatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  ConsumerState<PendingRequestsPage> createState() =>
      _PendingRequestsPageState();
}

class _PendingRequestsPageState
    extends ConsumerState<PendingRequestsPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color orange = Color(0xFFF47A24);
  static const Color blue = Color(0xFF2878E8);
  static const Color red = Color(0xFFE53935);

  int selectedFilter = 0;

  final List<String> filters = [
    'All',
    'Requested',
    'Confirmed',
    'Dispatched',
    'Returned',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Requested':
        return orange;
      case 'Confirmed':
        return blue;
      case 'Dispatched':
        return green;
      case 'Returned':
        return grey;
      default:
        return grey;
    }
  }

  Future<void> _updateStatus(String bookingId, String newStatus) async {
    try {
      await ref
          .read(bookingServiceProvider)
          .updateStatus(bookingId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $newStatus successfully'),
          backgroundColor: newStatus == 'Confirmed' ? green : red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allBookingsProvider);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Requests',
          style: TextStyle(
              color: dark, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          allAsync.whenData((all) {
            final pending =
                all.where((b) => b.status == 'Requested').length;
            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_rounded,
                      color: orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$pending pending',
                    style: const TextStyle(
                        color: orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).value ??
              const SizedBox.shrink(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildFilterChips(),
        ),
      ),
      body: allAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: green)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    color: red, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load bookings',
                    style: const TextStyle(
                        color: dark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: grey, fontSize: 12)),
              ],
            ),
          ),
        ),
        data: (all) {
          // Apply filter
          final filtered = selectedFilter == 0
              ? all
              : all
                  .where((b) => b.status == filters[selectedFilter])
                  .toList();

          if (filtered.isEmpty) return _buildEmptyState();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _buildRequestCard(filtered[index]),
          );
        },
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? green : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: isSelected ? green : border),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                    color: isSelected ? Colors.white : grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Request card ──────────────────────────────────────────────────
  Widget _buildRequestCard(BookingModel booking) {
    final color = _statusColor(booking.status);

    return GestureDetector(
      onTap: () {
        // Convert to map for existing BookingDetailPage compatibility
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(
              booking: {
                'id': booking.id,
                'client': booking.clientEmail,
                'event': booking.eventName,
                'dateRange': booking.dateRangeLabel,
                'items': booking.totalItems,
                'value': '${booking.totalItems} items',
                'status': booking.status,
                'timeAgo': booking.timeAgo,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top: ID + Status
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.assignment_rounded,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.id.length > 12
                                  ? 'BK-${booking.id.substring(booking.id.length - 8).toUpperCase()}'
                                  : booking.id,
                              style: const TextStyle(
                                color: dark,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(booking.status, color),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        booking.eventName,
                        style: const TextStyle(
                            color: dark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(height: 1, color: border),
            const SizedBox(height: 12),

            // Metadata row
            Row(
              children: [
                _buildMetaTag(Icons.person_outline_rounded,
                    booking.clientEmail),
                const SizedBox(width: 14),
                _buildMetaTag(Icons.calendar_today_outlined,
                    booking.dateRangeLabel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetaTag(Icons.inventory_2_outlined,
                    '${booking.totalItems} items'),
                const Spacer(),
                Text(
                  booking.timeAgo,
                  style: const TextStyle(
                      color: grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Action buttons for Requested status
            if (booking.status == 'Requested') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _updateStatus(booking.id, 'Cancelled'),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Reject',
                              style: TextStyle(
                                  color: red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () =>
                          _updateStatus(booking.id, 'Confirmed'),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: green.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('Approve',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Dispatch button for Confirmed status
            if (booking.status == 'Confirmed') ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () =>
                    _updateStatus(booking.id, 'Dispatched'),
                child: Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('Mark as Dispatched',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],

            // Return button for Dispatched status
            if (booking.status == 'Dispatched') ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () =>
                    _updateStatus(booking.id, 'Returned'),
                child: Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EBFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('Mark as Returned',
                        style: TextStyle(
                            color: Color(0xFF6D45D8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
                color: grey,
                fontSize: 10.5,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: green, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('All caught up!',
              style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 0
                ? 'No bookings yet.'
                : 'No ${filters[selectedFilter].toLowerCase()} bookings.',
            style:
                const TextStyle(color: grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
