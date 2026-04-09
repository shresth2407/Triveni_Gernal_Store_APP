import 'cart_item.dart';

class OrderRequest {
  final String userId;
  final String deliveryLocation;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod; // "UPI" | "COD"

  const OrderRequest({
    required this.userId,
    required this.deliveryLocation,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
  });
}
