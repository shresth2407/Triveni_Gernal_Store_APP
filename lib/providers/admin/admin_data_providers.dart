import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'admin_service_providers.dart';

final adminCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(adminProductServiceProvider).getCategories();
});

final adminProductsProvider = FutureProvider<List<Item>>((ref) {
  return ref.watch(adminProductServiceProvider).getProducts();
});

final adminOrdersProvider = StreamProvider<List<AdminOrder>>((ref) {
  return ref.watch(adminOrderServiceProvider).watchPendingOrders();
});
