import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discount.dart';
import '../services/discount_service.dart';

final discountServiceProvider = Provider<DiscountService>((ref) {
  return FirestoreDiscountService();
});

final activeDiscountsProvider = StreamProvider<List<Discount>>((ref) {
  return ref.watch(discountServiceProvider).watchActiveDiscounts();
});

final allDiscountsProvider = StreamProvider<List<Discount>>((ref) {
  return ref.watch(discountServiceProvider).watchAllDiscounts();
});
