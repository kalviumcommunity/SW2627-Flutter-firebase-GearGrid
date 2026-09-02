import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String name;
  final String category;
  final int totalQuantity;
  final int damagedQuantity;
  final int bufferHours;
  final List<String> tags;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.damagedQuantity,
    required this.bufferHours,
    required this.tags,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'other',
      totalQuantity: data['totalQuantity'] ?? 0,
      damagedQuantity: data['damagedQuantity'] ?? 0,
      bufferHours: data['bufferHours'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'totalQuantity': totalQuantity,
      'damagedQuantity': damagedQuantity,
      'bufferHours': bufferHours,
      'tags': tags,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
