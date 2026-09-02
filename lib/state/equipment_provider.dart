import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final equipmentListProvider = StreamProvider<List<Equipment>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamEquipment();
});
