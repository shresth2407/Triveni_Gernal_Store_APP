import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/cart_state.dart';
import '../models/item.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Adds one unit of [item]. If already in cart, increments quantity.
  void addItem(Item item) {
    final existing = state.items.indexWhere((ci) => ci.item.id == item.id);
    if (existing >= 0) {
      _updateQuantity(item.id, state.items[existing].quantity + 1);
    } else {
      state = CartState(items: [...state.items, CartItem(item: item, quantity: 1)]);
    }
  }

  /// Increments the quantity of the item with [itemId] by 1.
  void incrementItem(String itemId) {
    final existing = state.items.indexWhere((ci) => ci.item.id == itemId);
    if (existing >= 0) {
      _updateQuantity(itemId, state.items[existing].quantity + 1);
    }
  }

  /// Decrements the quantity of the item with [itemId] by 1.
  /// Removes the item entirely when quantity reaches 0.
  void decrementItem(String itemId) {
    final existing = state.items.indexWhere((ci) => ci.item.id == itemId);
    if (existing < 0) return;

    final currentQty = state.items[existing].quantity;
    if (currentQty <= 1) {
      state = CartState(
        items: state.items.where((ci) => ci.item.id != itemId).toList(),
      );
    } else {
      _updateQuantity(itemId, currentQty - 1);
    }
  }

  /// Clears all items from the cart.
  void clearCart() {
    state = const CartState();
  }

  /// Returns the current quantity of [itemId] in the cart (0 if not present).
  int quantityOf(String itemId) {
    final match = state.items.where((ci) => ci.item.id == itemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  void _updateQuantity(String itemId, int newQty) {
    state = CartState(
      items: state.items.map((ci) {
        if (ci.item.id == itemId) {
          return CartItem(item: ci.item, quantity: newQty);
        }
        return ci;
      }).toList(),
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
