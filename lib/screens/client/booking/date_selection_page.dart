import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../state/booking_draft_provider.dart';
import 'availability_catalog_page.dart';

class DateSelectionPage extends ConsumerStatefulWidget {
  const DateSelectionPage({super.key});

  @override
  ConsumerState<DateSelectionPage> createState() => _DateSelectionPageState();
}

class _DateSelectionPageState extends ConsumerState<DateSelectionPage> {
  static const Color green = Color(0xFF16845F);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF667085);

  Future<void> _selectDateRange(BuildContext context) async {
    final draft = ref.read(bookingDraftProvider);
    final initialDateRange = (draft.startDate != null && draft.endDate != null)
        ? DateTimeRange(start: draft.startDate!, end: draft.endDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: green,
              onPrimary: Colors.white,
              onSurface: dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(bookingDraftProvider.notifier).setDates(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    final hasDates = draft.startDate != null && draft.endDate != null;

    final dateFormat = DateFormat('MMM dd, yyyy');
    final startStr = draft.startDate != null ? dateFormat.format(draft.startDate!) : 'Select Start Date';
    final endStr = draft.endDate != null ? dateFormat.format(draft.endDate!) : 'Select End Date';

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
          'New Booking',
          style: TextStyle(
            color: dark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When is the event?',
                style: TextStyle(
                  color: dark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select the dates for this booking. This determines equipment availability.',
                style: TextStyle(
                  color: grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Date Picker Button
              GestureDetector(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6E9ED)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasDates ? '$startStr - $endStr' : 'Tap to select dates',
                              style: TextStyle(
                                color: hasDates ? dark : grey,
                                fontSize: 16,
                                fontWeight: hasDates ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                            if (hasDates) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${draft.endDate!.difference(draft.startDate!).inDays} nights',
                                style: const TextStyle(
                                  color: green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: grey,
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: hasDates
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AvailabilityCatalogPage(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    disabledBackgroundColor: const Color(0xFFE6E9ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue to Equipment',
                    style: TextStyle(
                      color: hasDates ? Colors.white : grey,
                      fontSize: 16,
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
}
