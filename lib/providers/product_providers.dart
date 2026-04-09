import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/item.dart';
import 'service_providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(productServiceProvider).getCategories();
});

final itemsProvider =
    FutureProvider.family<List<Item>, String?>((ref, categoryId) {
  return ref.watch(productServiceProvider).getItems(categoryId: categoryId);
});
