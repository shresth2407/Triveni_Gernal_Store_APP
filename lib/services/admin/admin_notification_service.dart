import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_order.dart';

abstract class AdminNotificationService {
  Stream<AdminOrder> watchNewOrders();
  void dispose();
}

class FirestoreAdminNotificationService implements AdminNotificationService {
  final FirebaseFirestore _firestore;
  StreamSubscription? _subscription;
  final StreamController<AdminOrder> _newOrderController = StreamController<AdminOrder>.broadcast();
  DateTime? _lastCheckTime;

  FirestoreAdminNotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _lastCheckTime = DateTime.now();
    _startListening();
  }

  void _startListening() {
    _subscription = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      
      final order = AdminOrder.fromFirestore(snapshot.docs.first);
      
      // Only notify if order is newer than last check time
      if (_lastCheckTime != null && order.createdAt.isAfter(_lastCheckTime!)) {
        _newOrderController.add(order);
      }
      
      // Update last check time
      _lastCheckTime = DateTime.now();
    });
  }

  @override
  Stream<AdminOrder> watchNewOrders() {
    return _newOrderController.stream;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _newOrderController.close();
  }
}
