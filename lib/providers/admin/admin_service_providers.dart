import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/admin/admin_auth_service.dart';
import '../../services/admin/admin_product_service.dart';
import '../../services/admin/admin_order_service.dart';
import '../../services/admin/admin_notification_service.dart';
import '../../services/admin/seed_service.dart';
import '../../models/admin_order.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return FirebaseAdminAuthService();
});

final adminProductServiceProvider = Provider<AdminProductService>((ref) {
  return FirestoreAdminProductService();
});

final adminOrderServiceProvider = Provider<AdminOrderService>((ref) {
  return FirestoreAdminOrderService();
});

final adminNotificationServiceProvider = Provider<AdminNotificationService>((ref) {
  return FirestoreAdminNotificationService();
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return FirestoreSeedService();
});

// Stream provider for latest orders (for dashboard)
final latestOrdersProvider = StreamProvider.family<List<AdminOrder>, int>((ref, limit) {
  final orderService = ref.watch(adminOrderServiceProvider);
  return orderService.watchLatestOrders(limit: limit);
});

// Stream provider for new order notifications
final newOrderNotificationsProvider = StreamProvider<AdminOrder>((ref) {
  final notificationService = ref.watch(adminNotificationServiceProvider);
  return notificationService.watchNewOrders();
});
