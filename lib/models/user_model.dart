import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String roleDisplay;
  final bool isActive;
  final String? companyName;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.roleDisplay,
    required this.isActive,
    this.companyName,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      roleDisplay: data['roleDisplay'] ?? 'client',
      isActive: data['isActive'] ?? true,
      companyName: data['companyName'],
    );
  }
}
