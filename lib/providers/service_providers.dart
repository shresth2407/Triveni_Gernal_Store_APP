import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';
import '../models/admin_order.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

final productServiceProvider = Provider<ProductService>((ref) {
  return FirestoreProductService();
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return FirestoreOrderService();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return UpiPaymentService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return FirestoreProfileService();
});

// Stream provider for user orders
final userOrdersProvider = StreamProvider<List<AdminOrder>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  
  final orderService = ref.watch(orderServiceProvider);
  return orderService.watchUserOrders(user.uid);
});

// Stream provider for user profile
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  
  final profileService = ref.watch(profileServiceProvider);
  return profileService.watchUserProfile(user.uid);
});
