import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

abstract class AdminOrderService {
  Stream<List<AdminOrder>> watchPendingOrders();
  Stream<List<AdminOrder>> watchLatestOrders({int limit = 10});
  Future<AdminOrder> getOrderById(String orderId);
  Future<void> updateOrderStatus(String orderId, String newStatus);
}

class FirestoreAdminOrderService implements AdminOrderService {
  final FirebaseFirestore _firestore;

  FirestoreAdminOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<AdminOrder>> watchPendingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'confirmed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AdminOrder.fromFirestore).toList());
  }

  @override
  Stream<List<AdminOrder>> watchLatestOrders({int limit = 10}) {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AdminOrder.fromFirestore).toList());
  }

  @override
  Future<AdminOrder> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    return AdminOrder.fromFirestore(doc);
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
