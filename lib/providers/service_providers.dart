import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final productServiceProvider = Provider<ProductService>((ref) {
  return FirestoreProductService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return FirestoreOrderService();
});

// final paymentServiceProvider = Provider<PaymentService>((ref) {
//   return UpiPaymentService();
// });
