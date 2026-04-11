import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart_item.dart';
import '../models/discount.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/discount_providers.dart';
import '../providers/product_providers.dart';
import '../providers/service_providers.dart';
import '../services/discount_engine.dart';
import '../widgets/discount_badge.dart';

// ─── DESIGN TOKENS (Matching HomeScreen) ─────────────────────────────
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
// ─────────────────────────────────────────────────────────────────────

/// Provider to fetch a single item by ID.
final _itemByIdProvider = FutureProvider.family<Item, String>((ref, id) {
  return ref.watch(productServiceProvider).getItemById(id);
});

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(_itemByIdProvider(itemId));
    // Fetch all items for "You Might Also Like"
    final allItemsAsync = ref.watch(itemsProvider(null));



    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: itemAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _kRed)),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (item) => _ItemDetailBody(item: item, allItemsAsync: allItemsAsync),
        ),
      ),
    );
  }
}

class _ItemDetailBody extends ConsumerWidget {
  final Item item;
  final AsyncValue<List<Item>> allItemsAsync;

  const _ItemDetailBody({required this.item, required this.allItemsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart state
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final qty = cartNotifier.quantityOf(item.id);

    // Resolve best discount via DiscountEngine
    final activeDiscountsAsync = ref.watch(activeDiscountsProvider);
    final activeDiscounts = activeDiscountsAsync.valueOrNull ?? [];
    final bestDiscount = DiscountEngine().bestDiscount(item, activeDiscounts);
    
    // Calculate discounted price for the total using DiscountEngine
    final totalPrice = qty > 0
        ? DiscountEngine()
            .computeLineTotal(
              CartItem(item: item, quantity: qty),
              activeDiscounts,
            )
            .toStringAsFixed(0)
        : '0';

    return Stack(
      children: [
        // ── SCROLLABLE CONTENT ────────────────────────────────────────
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HERO IMAGE SECTION ───────────────────────────────────
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      color: _kLightRed,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _kLightRed,
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: _kRoseBorder, size: 60),
                          ),
                        ),
                      ),
                    ),
                    // Top Actions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleBtn(
                            icon: Icons.arrow_back_ios_new,
                            onTap: () => context.pop(),
                          ),
                          Row(
                            children: [
                              // Cart button
                              if (cartState.items.isNotEmpty)
                                GestureDetector(
                                  onTap: () => context.push('/cart'),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _kWhite.withOpacity(0.85),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(Icons.shopping_bag_outlined, color: _kDarkRed, size: 20),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: _kRed,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              '${cartState.items.length}',
                                              style: const TextStyle(
                                                color: _kWhite,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _CircleBtn(
                                icon: Icons.share_outlined,
                                onTap: () {}, // TODO: Implement share
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── DETAILS CARD (Overlapping) ───────────────────────────
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Bottom padding for sticky bar
                  decoration: const BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand / Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kLightRed,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kRoseBorder),
                        ),
                        child: Text(
                          'TRIVENI FRESH', // Static brand or use Category name
                          style: const TextStyle(
                            color: _kRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Weight & Rating Row
                      Row(
                        children: [
                          Text(
                            '500g', // Assuming weight, ideally from model
                            style: const TextStyle(
                              color: _kTextGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: _kTextGrey, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Color(0xFFFF8F00), size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            '4.5 (120+ reviews)',
                            style: TextStyle(
                              color: _kTextMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Price Section — driven by DiscountEngine (Requirements 7.1–7.4)
                      _PriceSection(item: item, discount: bestDiscount),
                      const SizedBox(height: 15),

                      // Description
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: _kTextMid,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 11),

                      // ── YOU MIGHT ALSO LIKE ────────────────────────
                      const _SectionHeader(title: 'You Might Also Like'),
                      const SizedBox(height: 12),

                      allItemsAsync.when(
                        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: _kRed))),
                        error: (_,__) => const SizedBox(),
                        data: (allItems) {
                          final recommendations = allItems
                              .where((i) => i.id != item.id)
                              .take(5)
                              .toList();

                          if (recommendations.isEmpty) return const SizedBox();

                          return SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendations.length,
                              itemBuilder: (ctx, index) => _RecommendationCard(
                                item: recommendations[index],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── STICKY BOTTOM ACTION BAR ─────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: const BoxDecoration(
              color: _kWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Price Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kTextGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹$totalPrice',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  if (qty == 0)
                    GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(item);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _kRed.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: _kWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: _kLightRed,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kRed),
                      ),
                      child: Row(
                        children: [
                          // Minus
                          IconButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).decrementItem(item.id);
                              HapticFeedback.lightImpact();
                            },
                            icon: const Icon(Icons.remove, color: _kRed, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                          // Quantity
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$qty',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _kRed,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          // Plus
                          IconButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(item);
                              HapticFeedback.lightImpact();
                            },
                            icon: const Icon(Icons.add, color: _kRed, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═════════════════════════════════════════════════════════════════

/// Displays price and discount badge based on DiscountEngine result.
///
/// - percentage discount: DiscountBadge + discounted price + original strikethrough
/// - bogo/bulk discount:  DiscountBadge + original price only
/// - no discount:         original price only, no badge
class _PriceSection extends StatelessWidget {
  final Item item;
  final Discount? discount;

  const _PriceSection({required this.item, required this.discount});

  @override
  Widget build(BuildContext context) {
    if (discount == null) {
      // Requirement 7.4: no discount — show regular price only
      return Text(
        '₹${item.price.toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: _kTextDark,
          height: 0.9,
        ),
      );
    }

    if (discount!.type == DiscountType.percentage) {
      // Requirement 7.2: percentage — badge + discounted price + original strikethrough
      final discountedPrice =
          item.price * (1 - (discount!.value ?? 0) / 100);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiscountBadge(discount: discount!),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${discountedPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: _kTextGrey,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Requirement 7.3: bogo/bulk — badge + original price only
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiscountBadge(discount: discount!),
        const SizedBox(height: 6),
        Text(
          '₹${item.price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _kTextDark,
            height: 0.9,
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kWhite.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _kDarkRed, size: 20),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _kTextDark,
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Item item;

  const _RecommendationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/item/${item.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRoseBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x05000000), blurRadius: 5, offset: Offset(0,2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(color: _kLightRed),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kRed,
                    ),
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