import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

abstract class ProfileService {
  Future<UserProfile?> getUserProfile(String userId);
  Stream<UserProfile?> watchUserProfile(String userId);
  Future<void> updateProfile(String userId, String name, String phoneNumber, String address);
}

class FirestoreProfileService implements ProfileService {
  final FirebaseFirestore _firestore;

  FirestoreProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection('user_profiles')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  @override
  Future<void> updateProfile(String userId, String name, String phoneNumber, String address) async {
    final docRef = _firestore.collection('user_profiles').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
