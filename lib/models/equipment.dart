import 'package:flutter/material.dart';

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.powerProfile,
    required this.totalUnits,
    required this.accent,
    this.pricePerUnit = 0.0,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String powerProfile;
  final int totalUnits;
  final Color accent;
  /// Rental price per unit per event (in INR).
  final double pricePerUnit;
  /// Optional Firestore-hosted image URL for this equipment.
  final String? imageUrl;

  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? powerProfile,
    int? totalUnits,
    Color? accent,
    double? pricePerUnit,
    String? imageUrl,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      powerProfile: powerProfile ?? this.powerProfile,
      totalUnits: totalUnits ?? this.totalUnits,
      accent: accent ?? this.accent,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Equipment.fromMap(String id, Map<String, dynamic> data) {
    final parsedPrice = (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
    
    // Assign reasonable defaults based on category if price is 0 (legacy data)
    double defaultPrice = 1500.0;
    final cat = (data['category'] as String? ?? '').toLowerCase();
    if (cat.contains('sound') || cat.contains('audio')) defaultPrice = 3500.0;
    if (cat.contains('visual') || cat.contains('screen')) defaultPrice = 5000.0;
    if (cat.contains('light')) defaultPrice = 1200.0;
    if (cat.contains('furn')) defaultPrice = 800.0;

    return Equipment(
      id: id,
      name: data['name'] as String? ?? 'Untitled equipment',
      category: data['category'] as String? ?? 'General',
      description: data['description'] as String? ?? '',
      powerProfile: data['powerProfile'] as String? ?? '',
      totalUnits: (data['totalUnits'] as num?)?.toInt() ?? 0,
      accent: Color((data['accentValue'] as num?)?.toInt() ?? 0xFF52D1FF),
      pricePerUnit: parsedPrice <= 0.0 ? defaultPrice : parsedPrice,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'powerProfile': powerProfile,
      'totalUnits': totalUnits,
      'accentValue': accent.toARGB32(),
      'pricePerUnit': pricePerUnit,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
