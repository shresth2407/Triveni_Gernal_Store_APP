import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

abstract class AdminOrderService {
  Stream<List<AdminOrder>> watchPendingOrders();
  Future<AdminOrder> getOrderById(String orderId);
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
  Future<AdminOrder> getOrderById(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    return AdminOrder.fromFirestore(doc);
  }
}
