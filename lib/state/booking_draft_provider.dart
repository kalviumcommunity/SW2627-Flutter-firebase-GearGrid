import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingDraft {
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, int> selectedItems;

  BookingDraft({
    this.startDate,
    this.endDate,
    this.selectedItems = const {},
  });

  BookingDraft copyWith({
    DateTime? startDate,
    DateTime? endDate,
    Map<String, int>? selectedItems,
  }) {
    return BookingDraft(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedItems: selectedItems ?? this.selectedItems,
    );
  }
}

class BookingDraftNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => BookingDraft();

  void setDates(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void updateItemQuantity(String equipmentId, int quantity) {
    final newItems = Map<String, int>.from(state.selectedItems);
    if (quantity <= 0) {
      newItems.remove(equipmentId);
    } else {
      newItems[equipmentId] = quantity;
    }
    state = state.copyWith(selectedItems: newItems);
  }

  void clearDraft() {
    state = BookingDraft();
  }
}

final bookingDraftProvider =
    NotifierProvider<BookingDraftNotifier, BookingDraft>(() {
  return BookingDraftNotifier();
});
