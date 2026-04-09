import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

abstract class OrderService {
  Future<String> placeOrder(OrderRequest request); // returns orderId
}

class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _firestore;

  FirestoreOrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> placeOrder(OrderRequest request) async {
    final docRef = await _firestore.collection('orders').add({
      'userId': request.userId,
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
}
