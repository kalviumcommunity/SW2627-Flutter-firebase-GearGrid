import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../services/firestore_repository.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
class _C {
  static const ink = Color(0xFF0C1710);
  static const surface = Color(0xFFF6F4EE);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A9489);
  static const border = Color(0xFFE5E0D5);

  static TextStyle head(
          {double size = 22, Color color = const Color(0xFF0C1710)}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.8);

  static TextStyle body(
          {double size = 13,
          Color color = const Color(0xFF8A9489),
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.manrope(
          fontSize: size, fontWeight: weight, color: color, height: 1.45);
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    required this.user,
    required this.repository,
    super.key,
  });

  final AppUser user;
  final FirestoreRepository repository;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Orders', style: _C.head(size: 28, color: _C.ink)),
                  const SizedBox(height: 4),
                  Text('Track your equipment bookings', style: _C.body(size: 14)),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: widget.repository.watchBookings(user: widget.user),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.ink),
                  );
                }

                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 72, color: _C.muted),
                        const SizedBox(height: 16),
                        Text('No orders yet',
                            style: _C.head(size: 20, color: _C.ink)),
                        const SizedBox(height: 8),
                        Text(
                            'Add equipment to your cart and place your first booking.',
                            style: _C.body(size: 13, color: _C.muted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            // Can add navigation to home/browse here if needed.
                          },
                          child: Text(
                            'Browse Equipment →',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFFFF6B35),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort newest first by start date
                bookings.sort((a, b) => b.start.compareTo(a.start));

                return RefreshIndicator(
                  color: const Color(0xFF0C1710),
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final startInterval = (index * 0.1).clamp(0.0, 1.0);

                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animController,
                          curve: Interval(startInterval, 1.0,
                              curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animController,
                              curve: Interval(startInterval, 1.0,
                                  curve: Curves.easeOutCubic),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _OrderCard(booking: booking),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.booking});
  final Booking booking;

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.paid: return const Color(0xFF43A047);
      case BookingStatus.pending: return const Color(0xFFFBC02D);
      case BookingStatus.approved: return const Color(0xFF00ACC1);
      case BookingStatus.dispatched: return const Color(0xFFFF7043);
      case BookingStatus.completed: return const Color(0xFF66BB6A);
      case BookingStatus.rejected: return const Color(0xFF9BA9BC);
    }
  }

  IconData _statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.paid: return Icons.verified_rounded;
      case BookingStatus.pending: return Icons.schedule_rounded;
      case BookingStatus.approved: return Icons.thumb_up_rounded;
      case BookingStatus.dispatched: return Icons.local_shipping_rounded;
      case BookingStatus.completed: return Icons.task_alt_rounded;
      case BookingStatus.rejected: return Icons.cancel_rounded;
    }
  }

  Widget _buildStepper(BookingStatus status) {
    int currentStep = -1;
    bool isRejected = false;
    switch (status) {
      case BookingStatus.paid:
      case BookingStatus.pending:
        currentStep = 0;
        break;
      case BookingStatus.approved:
        currentStep = 1;
        break;
      case BookingStatus.dispatched:
        currentStep = 2;
        break;
      case BookingStatus.completed:
        currentStep = 3;
        break;
      case BookingStatus.rejected:
        isRejected = true;
        currentStep = -1;
        break;
    }

    final steps = ['Payment', 'Confirmed', 'Dispatched', 'Done'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index % 2 == 1) {
            // Line
            int stepIndex = index ~/ 2;
            bool isLineActive = !isRejected && currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isLineActive
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE5E0D5),
              ),
            );
          } else {
            // Circle
            int stepIndex = index ~/ 2;
            bool isDone = !isRejected && currentStep >= stepIndex;
            bool isCurrent = !isRejected && currentStep == stepIndex;
            final color =
                isDone ? const Color(0xFF43A047) : const Color(0xFFE5E0D5);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isCurrent ? 10 : 8,
                  height: isCurrent ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: isCurrent
                      ? Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.paddingOf(context).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${booking.id.substring(0, 8)}', style: _C.head(size: 20)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status.label,
                      style: GoogleFonts.manrope(
                        color: _statusColor(booking.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Event: ${booking.eventName}', style: _C.body(color: _C.ink, weight: FontWeight.w600)),
              Text('Venue: ${booking.venue}', style: _C.body()),
              Text('Dates: ${_fmtDate(booking.start)} - ${_fmtDate(booking.end)}', style: _C.body()),
              
              if (booking.driverName != null || booking.vehicleDetails != null || booking.deliveryEta != null) ...[
                const SizedBox(height: 20),
                Text('DISPATCH DETAILS', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: _C.muted)),
                const SizedBox(height: 8),
                if (booking.driverName != null) Text('Driver: ${booking.driverName}', style: _C.body(color: _C.ink)),
                if (booking.vehicleDetails != null) Text('Vehicle: ${booking.vehicleDetails}', style: _C.body(color: _C.ink)),
                if (booking.deliveryEta != null) Text('ETA: ${_fmtDate(booking.deliveryEta!)} at ${booking.deliveryEta!.hour}:${booking.deliveryEta!.minute.toString().padLeft(2, '0')}', style: _C.body(color: _C.ink)),
              ],

              const SizedBox(height: 20),
              Text('REQUESTED EQUIPMENT', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: _C.muted)),
              const SizedBox(height: 8),
              ...booking.requestedUnits.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: _C.body()),
                      Text('x${e.value}', style: _C.body(color: _C.ink, weight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Paid', style: _C.body(size: 14)),
                  Text('₹${booking.totalAmount.round()}', style: _C.head(size: 18)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sColor = _statusColor(booking.status);
    final itemCount = booking.requestedUnits.values.fold(0, (s, q) => s + q);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showOrderDetails(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(booking.status),
                          size: 14, color: sColor),
                      const SizedBox(width: 6),
                      Text(booking.status.label,
                          style: GoogleFonts.manrope(
                              color: sColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('#${booking.id.substring(0, 8)}',
                    style: GoogleFonts.spaceGrotesk(
                        color: _C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Divider(height: 1, color: _C.border.withValues(alpha: 0.5)),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.eventName,
                          style: _C.head(size: 16, color: _C.ink)),
                      const SizedBox(height: 4),
                      Text('${_fmtDate(booking.start)} · $itemCount items',
                          style: _C.body(size: 13)),
                    ],
                  ),
                ),
                if (booking.totalAmount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: _C.body(size: 10)),
                      Text('₹${booking.totalAmount.round()}',
                          style: GoogleFonts.spaceGrotesk(
                              color: _C.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
          ),

          // Stepper
          _buildStepper(booking.status),

          // Track / View Details CTA
          if (booking.status == BookingStatus.dispatched ||
              booking.status == BookingStatus.approved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F7F4),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      booking.status == BookingStatus.dispatched
                          ? Icons.local_shipping_outlined
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: _C.ink),
                  const SizedBox(width: 8),
                  Text(
                    booking.status == BookingStatus.dispatched
                        ? 'Track Delivery'
                        : 'View Details',
                    style: GoogleFonts.manrope(
                        color: _C.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
}
