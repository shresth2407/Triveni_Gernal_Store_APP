import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/admin/admin_auth_service.dart';
import '../../services/admin/admin_product_service.dart';
import '../../services/admin/admin_order_service.dart';
import '../../services/admin/seed_service.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return FirebaseAdminAuthService();
});

final adminProductServiceProvider = Provider<AdminProductService>((ref) {
  return FirestoreAdminProductService();
});

final adminOrderServiceProvider = Provider<AdminOrderService>((ref) {
  return FirestoreAdminOrderService();
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return FirestoreSeedService();
});
