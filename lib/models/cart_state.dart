import 'cart_item.dart';
import '../services/discount_engine.dart';

class CartState {
  final List<CartItem> items;
  final DiscountedCart? discountedCart;

  const CartState({this.items = const [], this.discountedCart});

  double get _rawTotal => items.fold(0, (sum, ci) => sum + ci.lineTotal);

  /// Falls back to raw total when [discountedCart] is null.
  double get grandTotal => discountedCart?.grandTotal ?? _rawTotal;

  /// Falls back to 0 when [discountedCart] is null.
  double get totalSavings => discountedCart?.totalSavings ?? 0;

  /// Kept for backward compatibility — same as [grandTotal].
  double get total => grandTotal;

  bool get isEmpty => items.isEmpty;
}
