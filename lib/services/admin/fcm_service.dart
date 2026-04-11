import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminFcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize(String adminUserId) async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToFirestore(adminUserId, token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(adminUserId, newToken);
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String adminUserId, String token) async {
    await _firestore.collection('admin_tokens').doc(adminUserId).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remove FCM token from Firestore (on logout)
  Future<void> removeToken(String adminUserId) async {
    await _firestore.collection('admin_tokens').doc(adminUserId).delete();
  }
}
