import '../models/cart_item.dart';
import '../models/discount.dart';
import '../models/item.dart';

/// Immutable result of a single discounted cart line.
class DiscountedLine {
  final CartItem cartItem;
  final Discount? appliedDiscount; // null if no discount applies
  final double originalLineTotal;
  final double discountedLineTotal;

  const DiscountedLine({
    required this.cartItem,
    required this.appliedDiscount,
    required this.originalLineTotal,
    required this.discountedLineTotal,
  });
}

/// Immutable result of DiscountEngine.compute.
class DiscountedCart {
  final List<DiscountedLine> lines;
  final double subtotal;      // sum of undiscounted line totals
  final double totalSavings;  // subtotal - grandTotal
  final double grandTotal;    // sum of discounted line totals

  const DiscountedCart({
    required this.lines,
    required this.subtotal,
    required this.totalSavings,
    required this.grandTotal,
  });
}

/// Pure computation class — no Firestore dependency.
///
/// Applies active discounts to cart items using best-discount-wins logic:
/// when multiple discounts match an item, the one producing the lowest
/// line total is selected (most beneficial for the customer).
class DiscountEngine {
  const DiscountEngine();

  /// Returns the best matching discount for [item] from [activeDiscounts],
  /// or null if none match.
  ///
  /// Scope matching rules:
  /// - scope == "product": matches only when item.id == discount.targetId
  /// - scope == "category": matches when item.categoryId == discount.targetId
  ///
  /// Among all matching discounts, the one producing the lowest line total
  /// for the item at quantity 1 is returned (best-for-customer).
  Discount? bestDiscount(Item item, List<Discount> activeDiscounts) {
    final matching = activeDiscounts.where((d) => _matches(item, d)).toList();
    if (matching.isEmpty) return null;

    // Pick the discount that produces the lowest line total at the item's
    // natural quantity of 1 for comparison purposes. We use a dummy quantity
    // of 1 here just to rank discounts; the actual line total is computed
    // separately with the real quantity.
    Discount best = matching.first;
    double bestTotal = _applyDiscount(item.price, 1, matching.first);

    for (final d in matching.skip(1)) {
      final total = _applyDiscount(item.price, 1, d);
      if (total < bestTotal) {
        bestTotal = total;
        best = d;
      }
    }

    return best;
  }

  /// Returns the discounted line total for [cartItem] given [activeDiscounts].
  ///
  /// Selects the best (lowest-total) matching discount and applies it.
  /// Returns price × quantity when the list is empty or no discount matches.
  double computeLineTotal(CartItem cartItem, List<Discount> activeDiscounts) {
    if (activeDiscounts.isEmpty) {
      return cartItem.item.price * cartItem.quantity;
    }

    final matching = activeDiscounts
        .where((d) => _matches(cartItem.item, d))
        .toList();

    if (matching.isEmpty) {
      return cartItem.item.price * cartItem.quantity;
    }

    // Find the discount that produces the lowest line total for this quantity.
    double bestTotal = _applyDiscount(
      cartItem.item.price,
      cartItem.quantity,
      matching.first,
    );

    for (final d in matching.skip(1)) {
      final total = _applyDiscount(cartItem.item.price, cartItem.quantity, d);
      if (total < bestTotal) {
        bestTotal = total;
      }
    }

    return bestTotal;
  }

  /// Computes a full [DiscountedCart] from [items] and [activeDiscounts].
  DiscountedCart compute(
    List<CartItem> items,
    List<Discount> activeDiscounts,
  ) {
    final lines = <DiscountedLine>[];

    for (final cartItem in items) {
      final original = cartItem.item.price * cartItem.quantity;

      final matching = activeDiscounts
          .where((d) => _matches(cartItem.item, d))
          .toList();

      Discount? applied;
      double discounted = original;

      if (matching.isNotEmpty) {
        applied = matching.first;
        discounted = _applyDiscount(
          cartItem.item.price,
          cartItem.quantity,
          matching.first,
        );

        for (final d in matching.skip(1)) {
          final total = _applyDiscount(
            cartItem.item.price,
            cartItem.quantity,
            d,
          );
          if (total < discounted) {
            discounted = total;
            applied = d;
          }
        }
      }

      lines.add(DiscountedLine(
        cartItem: cartItem,
        appliedDiscount: applied,
        originalLineTotal: original,
        discountedLineTotal: discounted,
      ));
    }

    final subtotal = lines.fold(0.0, (sum, l) => sum + l.originalLineTotal);
    final grandTotal = lines.fold(0.0, (sum, l) => sum + l.discountedLineTotal);
    final totalSavings = subtotal - grandTotal;

    return DiscountedCart(
      lines: lines,
      subtotal: subtotal,
      totalSavings: totalSavings,
      grandTotal: grandTotal,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [discount] applies to [item] based on scope/targetId.
  bool _matches(Item item, Discount discount) {
    switch (discount.scope) {
      case DiscountScope.product:
        return item.id == discount.targetId;
      case DiscountScope.category:
        return item.categoryId == discount.targetId;
    }
  }

  /// Computes the line total for [price] × [quantity] under [discount].
  ///
  /// Formulas (Requirements 5.3–5.6, 5.8):
  /// - percentage: P × (1 − V/100) × Q
  /// - bogo:       payable × P  where payable = (Q ÷ (B+F)) × B + (Q mod (B+F))
  /// - bulk Q≥M:   P × (1 − D/100) × Q
  /// - bulk Q<M:   P × Q  (no discount)
  double _applyDiscount(double price, int quantity, Discount discount) {
    switch (discount.type) {
      case DiscountType.percentage:
        final v = discount.value ?? 0.0;
        return price * (1 - v / 100) * quantity;

      case DiscountType.bogo:
        final b = discount.buyQty ?? 1;
        final f = discount.freeQty ?? 1;
        final groupSize = b + f;
        final payable = (quantity ~/ groupSize) * b + (quantity % groupSize);
        return payable * price;

      case DiscountType.bulk:
        final m = discount.minQty ?? 2;
        final d = discount.discountPercent ?? 0.0;
        if (quantity >= m) {
          return price * (1 - d / 100) * quantity;
        }
        return price * quantity;
    }
  }
}
