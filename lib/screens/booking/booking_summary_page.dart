import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../state/booking_draft_provider.dart';
import '../../state/auth_provider.dart';
import '../../services/functions_service.dart';

// Copying mock data for display purposes
class CatalogItem {
  final String id;
  final String name;
  final String category;
  final String brand;
  final int available;
  final String imagePath;

  CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.available,
    required this.imagePath,
  });
}

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

  final List<CatalogItem> allEquipment = [
    CatalogItem(
      id: 'AUD-001',
      name: 'JBL PA Speaker',
      category: 'Sound',
      brand: 'JBL',
      available: 7,
      imagePath: 'assets/equipment/jbl_pa_speaker.png',
    ),
    CatalogItem(
      id: 'LGT-002',
      name: 'Beam 230 Moving Head',
      category: 'Lighting',
      brand: 'Philips',
      available: 10,
      imagePath: 'assets/equipment/beam_230_moving_head.png',
    ),
    CatalogItem(
      id: 'AUD-003',
      name: 'Shure SM58 Microphone',
      category: 'Sound',
      brand: 'Shure',
      available: 1,
      imagePath: 'assets/equipment/shure_sm58_microphone.png',
    ),
    CatalogItem(
      id: 'STG-004',
      name: 'Aluminum Truss 12ft',
      category: 'Lighting',
      brand: 'Global Truss',
      available: 18,
      imagePath: 'assets/equipment/aluminum_truss_12ft.png',
    ),
    CatalogItem(
      id: 'FUR-005',
      name: 'Banquet Chair',
      category: 'Furniture',
      brand: 'GearGrid',
      available: 5,
      imagePath: 'assets/equipment/banquet_chair.png',
    ),
  ];

  bool _isSubmitting = false;

  void _submitBooking() async {
    final draft = ref.read(bookingDraftProvider);
    final userProfile = ref.read(userProfileProvider).value;
    
    if (draft.startDate == null || draft.endDate == null || userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing booking details or user profile')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final List<Map<String, dynamic>> equipmentList = [];
      draft.selectedItems.forEach((id, quantity) {
        if (quantity > 0) {
          final item = allEquipment.firstWhere((e) => e.id == id, orElse: () => allEquipment[0]);
          equipmentList.add({
            'equipmentId': item.id,
            'equipmentName': item.name,
            'category': item.category,
            'quantity': quantity,
          });
        }
      });

      final functions = FunctionsService();
      await functions.createBookingRequest(
        clientName: userProfile.name,
        contactPhone: userProfile.phone ?? 'Unknown',
        startDateTime: draft.startDate!,
        endDateTime: draft.endDate!,
        equipmentRequested: equipmentList,
      );

      if (!mounted) return;
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                    child: const Icon(Icons.check_circle_rounded, color: green, size: 32),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Booking Requested',
                    style: TextStyle(
                      color: dark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your booking request has been submitted for approval. You can track its status in the Bookings tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Clear draft and pop to dashboard
                        ref.read(bookingDraftProvider.notifier).clearDraft();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    final startDateStr = draft.startDate != null ? dateFormat.format(draft.startDate!) : '';
    final endDateStr = draft.endDate != null ? dateFormat.format(draft.endDate!) : '';
    final totalNights = draft.startDate != null && draft.endDate != null 
        ? draft.endDate!.difference(draft.startDate!).inDays 
        : 0;

    // Filter to only items that were selected
    final List<MapEntry<CatalogItem, int>> cartItems = [];
    draft.selectedItems.forEach((id, quantity) {
      if (quantity > 0) {
        final item = allEquipment.firstWhere((e) => e.id == id, orElse: () => allEquipment[0]);
        cartItems.add(MapEntry(item, quantity));
      }
    });

    final totalQuantity = cartItems.fold(0, (sum, entry) => sum + entry.value);

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
                    // Dates Section
                    const Text(
                      'Event Dates',
                      style: TextStyle(
                        color: dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
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
                          const Icon(Icons.calendar_month_rounded, color: green, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$startDateStr - $endDateStr',
                                  style: const TextStyle(
                                    color: dark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalNights nights',
                                  style: const TextStyle(
                                    color: grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Equipment Section
                    Row(
                      children: [
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            color: dark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalQuantity Items',
                          style: const TextStyle(
                            color: green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: List.generate(cartItems.length, (index) {
                          final item = cartItems[index].key;
                          final quantity = cartItems[index].value;
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: index < cartItems.length - 1 
                                  ? const Border(bottom: BorderSide(color: border))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.asset(item.imagePath, fit: BoxFit.contain),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: dark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${item.id}',
                                        style: const TextStyle(
                                          color: grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'x$quantity',
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
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: border),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
