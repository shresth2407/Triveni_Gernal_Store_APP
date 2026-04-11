import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrderItem {
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const AdminOrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory AdminOrderItem.fromMap(Map<String, dynamic> map) {
    return AdminOrderItem(
      productId: map['productId'] as String,
      name: map['name'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      lineTotal: (map['lineTotal'] as num).toDouble(),
    );
  }
}

class AdminOrder {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryLocation;
  final List<AdminOrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  const AdminOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryLocation,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory AdminOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return AdminOrder(
      id: doc.id,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? '',
      userPhone: data['userPhone'] as String? ?? '',
      deliveryLocation: data['deliveryLocation'] as String,
      items: rawItems
          .map((e) => AdminOrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
