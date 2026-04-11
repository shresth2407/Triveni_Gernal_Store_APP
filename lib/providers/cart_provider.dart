import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/cart_state.dart';
import '../models/item.dart';
import '../services/discount_engine.dart';
import 'discount_providers.dart';

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  CartNotifier(this._ref) : super(const CartState()) {
    // Watch activeDiscountsProvider so we recompute whenever discounts change.
    _ref.listen(activeDiscountsProvider, (_, __) => _recompute());
  }

  // ---------------------------------------------------------------------------
  // Public API (unchanged)
  // ---------------------------------------------------------------------------

  /// Adds one unit of [item].
  void addItem(Item item) {
    final existing =
        state.items.indexWhere((ci) => ci.item.id == item.id);

    if (existing >= 0) {
      _updateQuantity(item.id, state.items[existing].quantity + 1);
    } else {
      _setItems([...state.items, CartItem(item: item, quantity: 1)]);
    }
  }

  void incrementItem(String itemId) {
    final existing =
        state.items.indexWhere((ci) => ci.item.id == itemId);
    if (existing >= 0) {
      _updateQuantity(itemId, state.items[existing].quantity + 1);
    }
  }

  void decrementItem(String itemId) {
    final existing =
        state.items.indexWhere((ci) => ci.item.id == itemId);
    if (existing < 0) return;

    final currentQty = state.items[existing].quantity;
    if (currentQty <= 1) {
      _setItems(state.items.where((ci) => ci.item.id != itemId).toList());
    } else {
      _updateQuantity(itemId, currentQty - 1);
    }
  }

  void clearCart() {
    state = const CartState();
  }

  int quantityOf(String itemId) {
    final match = state.items.where((ci) => ci.item.id == itemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  // ---------------------------------------------------------------------------
  // Legacy helpers — kept for backward compatibility with existing UI code.
  // Delegates to CartState / DiscountEngine so the UI doesn't need to change.
  // ---------------------------------------------------------------------------

  /// Grand total after discounts (delegates to [CartState.grandTotal]).
  double get total => state.grandTotal;

  /// Total savings across all cart items (delegates to [CartState.totalSavings]).
  double get totalSavings => state.totalSavings;

  /// Computes the discounted line total for a single item at a given quantity.
  /// Uses the current active discounts from [activeDiscountsProvider].
  double calculateItemTotal(Item item, int qty) {
    final cartItem = CartItem(item: item, quantity: qty);
    final discountsAsync = _ref.read(activeDiscountsProvider);
    final activeDiscounts = discountsAsync.when(
      data: (list) => list,
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );
    return const DiscountEngine()
        .computeLineTotal(cartItem, List.from(activeDiscounts));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setItems(List<CartItem> items) {
    final discounted = _computeDiscountedCart(items);
    state = CartState(items: items, discountedCart: discounted);
  }

  void _updateQuantity(String itemId, int newQty) {
    final items = state.items.map((ci) {
      if (ci.item.id == itemId) {
        return CartItem(item: ci.item, quantity: newQty);
      }
      return ci;
    }).toList();
    _setItems(items);
  }

  /// Called whenever [activeDiscountsProvider] emits a new value or error.
  void _recompute() {
    final discounted = _computeDiscountedCart(state.items);
    state = CartState(items: state.items, discountedCart: discounted);
  }

  /// Runs [DiscountEngine.compute] with the current active discounts.
  /// Falls back to an empty discount list on error (Req 5.1, error handling).
  DiscountedCart _computeDiscountedCart(List<CartItem> items) {
    final discountsAsync = _ref.read(activeDiscountsProvider);
    final activeDiscounts = discountsAsync.when(
      data: (list) => list,
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );
    return const DiscountEngine().compute(items, List.from(activeDiscounts));
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
