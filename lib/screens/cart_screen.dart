import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

// ─── DESIGN TOKENS (Same as home_screen) ─────────────────────────
const _kRed         = Color(0xFFDC143C);
const _kDarkRed     = Color(0xFFB22222);
const _kLightRed    = Color(0xFFFFF0F0);
const _kRoseBorder  = Color(0xFFFFCDD2);
const _kBg          = Color(0xFFF7F7F7);
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF1A1A1A);
const _kTextGrey    = Color(0xFF9E9E9E);
const _kTextMid     = Color(0xFF555555);
const _kGreen       = Color(0xFF2E7D32);
const _kGreenBright = Color(0xFF43A047);
const _kGreenLight  = Color(0xFFE8F5E9);

// ═════════════════════════════════════════════════════════════════
// CART SCREEN
// ═════════════════════════════════════════════════════════════════
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState   = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,

        // ── MODERN APP BAR ───────────────────────────────────────
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          shadowColor: Colors.black.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
          titleSpacing: 16,
          title: Row(
            children: [
              _ModernIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.go('/home'),
              ),
              const SizedBox(width: 16),
              const Text(
                'My Cart',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            if (cartState.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${cartState.items.length} Items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kDarkRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),

        body: cartState.items.isEmpty
            ? const _ModernEmptyCartView()
            : Column(
          children: [
            // ── DELIVERY INFO STRIP ────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: _kWhite, size: 13),
                        SizedBox(width: 4),
                        Text(
                          '8 Mins',
                          style: TextStyle(
                              color: _kWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '📍 Delivery to Patna',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kTextMid,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ── CART ITEMS LIST ────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cartState.items.length,
                itemBuilder: (_, i) {
                  final ci = cartState.items[i];
                  return _ModernCartItemCard(
                    cartItem: ci,
                    onIncrement: () {
                      cartNotifier.incrementItem(ci.item.id);
                      HapticFeedback.lightImpact();
                    },
                    onDecrement: () {
                      cartNotifier.decrementItem(ci.item.id);
                      HapticFeedback.lightImpact();
                    },
                  );
                },
              ),
            ),

            // ── COUPON SECTION ────────────────────────────
            _ModernCouponStrip(),

            // ── BILL SUMMARY ───────────────────────────────
            _ModernBillSummary(total: cartState.total),

            // ── CHECKOUT BAR (Floating Style) ───────────────
            _ModernCheckoutBar(
              total: cartState.total,
              itemCount: cartState.items.length,
              onCheckout: () => context.go('/checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN EMPTY CART VIEW
// ═════════════════════════════════════════════════════════════════
class _ModernEmptyCartView extends StatelessWidget {
  const _ModernEmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: _kLightRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 70, color: _kRed),
            ),
            const SizedBox(height: 30),
            const Text(
              'Cart is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Looks like you haven\'t added\nanything yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: _kTextGrey, height: 1.5),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient:
                  const LinearGradient(colors: [_kDarkRed, _kRed]),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                        color: _kRed.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined,
                        color: _kWhite, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Start Shopping',
                      style: TextStyle(
                        color: _kWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN CART ITEM CARD
// ═════════════════════════════════════════════════════════════════
class _ModernCartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ModernCartItemCard({
    required this.cartItem,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final item = cartItem.item;
    final mrp  = (item.price * 1.2).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kLightRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: _kRoseBorder, size: 32)),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price Row
                  Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹$mrp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextGrey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGreenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '20% OFF',
                          style: TextStyle(
                            fontSize: 10,
                            color: _kGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: Stepper & Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Modern Stepper
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModernStepperBtn(
                                icon: Icons.remove,
                                onTap: onDecrement),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _kTextDark,
                                ),
                              ),
                            ),
                            _ModernStepperBtn(
                                icon: Icons.add,
                                onTap: onIncrement),
                          ],
                        ),
                      ),
                      // Total
                      Text(
                        '₹${cartItem.lineTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN STEPPER BUTTON
// ═════════════════════════════════════════════════════════════════
class _ModernStepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModernStepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: _kWhite,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2)
              )
            ]
        ),
        child: Icon(icon, color: _kRed, size: 20),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN COUPON STRIP
// ═════════════════════════════════════════════════════════════════
class _ModernCouponStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kLightRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_offer_outlined,
                color: _kRed, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Apply Coupon',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark)),
                SizedBox(height: 2),
                Text('Save more with coupons',
                    style: TextStyle(fontSize: 12, color: _kTextGrey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: _kTextGrey, size: 24),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN BILL SUMMARY
// ═════════════════════════════════════════════════════════════════
class _ModernBillSummary extends StatelessWidget {
  final double total;

  const _ModernBillSummary({required this.total});

  @override
  Widget build(BuildContext context) {
    final delivery = total >= 149 ? 0.0 : 30.0;
    final savings  = total * 0.20;
    final grand    = total + delivery;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _BillRow(
              label: 'Item Total',
              value: '₹${total.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Delivery Fee',
            value: delivery == 0 ? 'FREE' : '₹${delivery.toStringAsFixed(0)}',
            valueColor: delivery == 0 ? _kGreenBright : _kTextDark,
          ),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Discount (20%)',
            value: '- ₹${savings.toStringAsFixed(0)}',
            valueColor: _kGreenBright,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _kBg),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                ),
              ),
              Text(
                '₹${grand.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: _kTextMid, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _kTextDark,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN CHECKOUT BAR (Light Above / Floating Style)
// ═════════════════════════════════════════════════════════════════
class _ModernCheckoutBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;

  const _ModernCheckoutBar({
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    color: _kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: _kTextDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main CTA
            GestureDetector(
              onTap: onCheckout,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDarkRed, _kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$itemCount Item${itemCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: _kWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER: MODERN ICON BUTTON (Back Button) ─────────────────────
class _ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModernIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _kTextDark, size: 18),
      ),
    );
  }
}