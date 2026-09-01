import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../state/booking_draft_provider.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';

class BookingSummaryPage extends ConsumerStatefulWidget {
  const BookingSummaryPage({super.key});

  @override
  ConsumerState<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends ConsumerState<BookingSummaryPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);
  static const Color border = Color(0xFFE6E9ED);

  bool _isSubmitting = false;

  // Cached equipment names for display (from Firestore equipment collection)
  final Map<String, Map<String, dynamic>> _equipmentCache = {};

  @override
  void initState() {
    super.initState();
    _loadEquipmentNames();
  }

  Future<void> _loadEquipmentNames() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('equipment').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        _equipmentCache[doc.id] = {
          'name': data['name'] ?? 'Unknown',
          'category': data['category'] ?? '',
        };
        // Also index by equipmentId field if present
        final eid = data['equipmentId']?.toString();
        if (eid != null && eid.isNotEmpty) {
          _equipmentCache[eid] = {
            'name': data['name'] ?? 'Unknown',
            'category': data['category'] ?? '',
          };
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _submitBooking() async {
    final draft = ref.read(bookingDraftProvider);

    if (draft.startDate == null || draft.endDate == null) {
      _showSnack('Please select event dates first.');
      return;
    }

    final cartItems = draft.selectedItems.entries
        .where((e) => e.value > 0)
        .toList();

    if (cartItems.isEmpty) {
      _showSnack('Please add at least one equipment item.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final bookingItems = cartItems.map((entry) {
        final cached = _equipmentCache[entry.key];
        return BookingItem(
          equipmentId: entry.key,
          name: cached?['name'] as String? ?? entry.key,
          category: cached?['category'] as String? ?? '',
          quantity: entry.value,
        );
      }).toList();

      final booking = BookingModel(
        id: '',
        clientId: user.uid,
        clientEmail: user.email ?? '',
        eventName: 'Event on ${DateFormat('MMM dd').format(draft.startDate!)}',
        startDate: draft.startDate!,
        endDate: draft.endDate!,
        status: 'Requested',
        items: bookingItems,
        totalItems: cartItems.fold(0, (s, e) => s + e.value),
        createdAt: DateTime.now(),
      );

      await ref.read(bookingServiceProvider).createBooking(booking);

      if (!mounted) return;

      // Clear the draft
      ref.read(bookingDraftProvider.notifier).clearDraft();

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit booking: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: green, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Requested!',
                style: TextStyle(
                  color: dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your booking request has been submitted for admin approval. You can track its status in the Bookings tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');

    final startDateStr =
        draft.startDate != null ? dateFormat.format(draft.startDate!) : '—';
    final endDateStr =
        draft.endDate != null ? dateFormat.format(draft.endDate!) : '—';
    final totalNights =
        draft.startDate != null && draft.endDate != null
            ? draft.endDate!.difference(draft.startDate!).inDays
            : 0;

    final cartItems = draft.selectedItems.entries
        .where((e) => e.value > 0)
        .toList();

    final totalQuantity = cartItems.fold(0, (s, e) => s + e.value);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Review Booking',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Dates ──────────────────────────────────────
                    const Text(
                      'Event Dates',
                      style: TextStyle(
                          color: dark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              color: green, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$startDateStr – $endDateStr',
                                  style: const TextStyle(
                                      color: dark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalNights night${totalNights == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                      color: grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Equipment ──────────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Equipment',
                          style: TextStyle(
                              color: dark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(
                          '$totalQuantity Item${totalQuantity == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: green,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (cartItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: const Center(
                          child: Text(
                            'No items selected',
                            style: TextStyle(color: grey, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children:
                              List.generate(cartItems.length, (index) {
                            final entry = cartItems[index];
                            final cached =
                                _equipmentCache[entry.key];
                            final name = cached?['name'] as String? ??
                                entry.key;
                            final category =
                                cached?['category'] as String? ?? '';
                            final qty = entry.value;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: index < cartItems.length - 1
                                    ? const Border(
                                        bottom: BorderSide(
                                            color: border))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFFEAF7F1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_rounded,
                                      color: green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: dark,
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                        if (category.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            category,
                                            style: const TextStyle(
                                                color: grey,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'x$qty',
                                    style: const TextStyle(
                                      color: dark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Bar ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    disabledBackgroundColor: green.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
