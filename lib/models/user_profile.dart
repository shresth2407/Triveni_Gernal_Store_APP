import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final String phoneNumber;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      address: data['address'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isComplete {
    return name.isNotEmpty && phoneNumber.isNotEmpty && address.isNotEmpty;
  }
}
