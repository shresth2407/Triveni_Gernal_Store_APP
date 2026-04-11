import 'cart_item.dart';

class OrderRequest {
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryLocation;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod; // "UPI" | "COD"

  const OrderRequest({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryLocation,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
  });
}
