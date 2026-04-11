import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

abstract class OrderService {
  Future<String> placeOrder(OrderRequest request); // returns orderId
  Stream<List<AdminOrder>> watchUserOrders(String userId);
}

class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _firestore;

  FirestoreOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> placeOrder(OrderRequest request) async {
    final docRef = await _firestore.collection('orders').add({
      'userId': request.userId,
      'userName': request.userName,
      'userPhone': request.userPhone,
      'deliveryLocation': request.deliveryLocation,
      'items': request.items.map((cartItem) => {
        'productId': cartItem.item.id,
        'name': cartItem.item.name,
        'unitPrice': cartItem.item.price,
        'quantity': cartItem.quantity,
        'lineTotal': cartItem.lineTotal,
      }).toList(),
      'totalAmount': request.totalAmount,
      'paymentMethod': request.paymentMethod,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  @override
  Stream<List<AdminOrder>> watchUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(AdminOrder.fromFirestore).toList());
  }
}
