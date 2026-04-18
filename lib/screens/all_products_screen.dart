import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../models/category.dart';
import '../models/discount.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/discount_providers.dart';
import '../providers/product_providers.dart';
import '../services/discount_engine.dart';
import '../widgets/discount_badge.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
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

class AllProductsScreen extends ConsumerStatefulWidget {
  const AllProductsScreen({super.key});

  @override
  ConsumerState<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends ConsumerState<AllProductsScreen> {
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(itemsProvider(_selectedCategoryId));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync      = ref.watch(itemsProvider(_selectedCategoryId));
    final cartState       = ref.watch(cartProvider);
    final activeDiscounts = ref.watch(activeDiscountsProvider).valueOrNull ?? [];

    // Filter Logic
    final filteredItems = itemsAsync.when(
      data: (items) {
        if (_searchQuery.isEmpty) return items;
        return items
            .where((i) => i.name.toLowerCase().contains(_searchQuery))
            .toList();
      },
      loading: () => <Item>[],
      error:   (_, __) => <Item>[],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        
        // ── APP BAR ──────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _kTextDark, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'All Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kTextDark,
            ),
          ),
          actions: [
            // Cart button
            if (cartState.items.isNotEmpty)
              GestureDetector(
                onTap: () => context.push('/cart'),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kRoseBorder, width: 1.5),
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
          ],
        ),

        body: Column(
          children: [
            // ── SEARCH BAR ────────────────────────────────────────
            Container(
              color: _kWhite,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: _kLightRed,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kRoseBorder, width: 1.5),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: _kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: _kDarkRed, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: _kDarkRed, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
                  ),
                ),
              ),
            ),




            // ── CATEGORIES FILTER ──────────────────────────────────
        categoriesAsync.when(
          // ✨ SHIMMER LOADER
          loading: () => Container(
            color: _kWhite,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 16,
                    width: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (_, __) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          error: (_, __) => const SizedBox(),

          data: (cats) {
            // ✅ AUTO SELECT FIRST CATEGORY
            if (_selectedCategoryId == null && cats.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedCategoryId = cats.first.id;
                });
              });
            }

            return Container(
              color: _kWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 90,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      children: [
                        // ❌ "All" removed
                        ...cats.map((c) => _CategoryChip(
                          label: c.name,
                          imageUrl: c.imageUrl,
                          selected: _selectedCategoryId == c.id,
                          onTap: () => setState(() => _selectedCategoryId = c.id),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

            // ── PRODUCTS GRID ──────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: _kRed,
                child: itemsAsync.when(
                  loading: () => const _ProductGridShimmer(),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: _kRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load products',
                          style: const TextStyle(color: _kTextMid, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRed,
                            foregroundColor: _kWhite,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (_) {
                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: _kTextGrey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No products found for "$_searchQuery"'
                                  : 'No products available',
                              style: const TextStyle(color: _kTextGrey, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (_, i) => _ProductCard(
                        item: filteredItems[i],
                        activeDiscounts: activeDiscounts,
                      ),
                    );
                  },
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
// CATEGORY CHIP WITH IMAGE
// ═════════════════════════════════════════════════════════════════
class _CategoryChip extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: selected ? _kLightRed : _kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kRed : _kRoseBorder,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _kRed.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: selected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _kRed.withOpacity(0.08)
                    : Colors.grey.shade100,
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.category, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? _kRed : _kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CATEGORY FILTER CHIP (DEPRECATED - KEPT FOR COMPATIBILITY)
// ═════════════════════════════════════════════════════════════════
class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kRed : _kLightRed,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kRed : _kRoseBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? _kWhite : _kDarkRed,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PRODUCT CARD
// ═════════════════════════════════════════════════════════════════
// class _ProductCard extends ConsumerStatefulWidget {
//   final Item item;
//   final List<Discount> activeDiscounts;
//
//   const _ProductCard({
//     required this.item,
//     required this.activeDiscounts,
//   });
//
//   @override
//   ConsumerState<_ProductCard> createState() => _ProductCardState();
// }
//
// class _ProductCardState extends ConsumerState<_ProductCard> {
//   bool _added = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final bestDiscount = const DiscountEngine().bestDiscount(widget.item, widget.activeDiscounts);
//
//     return GestureDetector(
//       onTap: () => context.push('/item/${widget.item.id}'),
//       child: Container(
//         decoration: BoxDecoration(
//           color: _kWhite,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: _kRoseBorder, width: 1.5),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x10B22222),
//               blurRadius: 8,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Image with discount badge
//             Expanded(
//               child: Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
//                     child: Container(
//                       color: _kLightRed,
//                       child:ClipRRect(
//                         borderRadius: const BorderRadius.vertical(
//                           top: Radius.circular(14),
//                         ),
//                         child: Container(
//                           height: 140, // 🔥 FIXED HEIGHT (adjust 120–160 as per UI)
//                           width: double.infinity,
//                           color: _kLightRed,
//                           child: Image.network(
//                             widget.item.imageUrl,
//                             fit: BoxFit.fitWidth, // ✅ fills horizontally
//                             alignment: Alignment.topCenter, // optional (better UX)
//                             errorBuilder: (_, __, ___) => const Icon(
//                               Icons.image_not_supported,
//                               color: _kRoseBorder,
//                               size: 40,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   if (bestDiscount != null)
//                     Positioned(
//                       top: 8,
//                       left: 8,
//                       child: DiscountBadge(discount: bestDiscount),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Product details
//             Padding(
//               padding: const EdgeInsets.all(10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.item.name,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w700,
//                       color: _kTextDark,
//                       height: 1.2,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         '₹${widget.item.price.toStringAsFixed(0)}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w800,
//                           color: _kRed,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTap: () {
//                           ref.read(cartProvider.notifier).addItem(widget.item);
//                           HapticFeedback.lightImpact();
//                           setState(() => _added = true);
//
//                           Future.delayed(const Duration(seconds: 2), () {
//                             if (mounted) setState(() => _added = false);
//                           });
//
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('${widget.item.name} added to cart!'),
//                               backgroundColor: _kRed,
//                               duration: const Duration(seconds: 1),
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           );
//                         },
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: _added
//                                   ? [_kGreen, _kGreenBright]
//                                   : [_kDarkRed, _kRed],
//                             ),
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: (_added ? _kGreen : _kRed).withOpacity(0.4),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Icon(
//                             _added ? Icons.check : Icons.add,
//                             color: _kWhite,
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//
// }

class _ProductCard extends ConsumerStatefulWidget {
  final Item item;
  final List<Discount> activeDiscounts;

  const _ProductCard({required this.item, required this.activeDiscounts});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final mrp = (widget.item.price * 1.2).toStringAsFixed(0);

    // Get best discount for this item
    final bestDiscount = const DiscountEngine().bestDiscount(widget.item, widget.activeDiscounts);

    return GestureDetector(
      onTap: () => context.push('/item/${widget.item.id}'),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kRoseBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10B22222),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          color: _kLightRed,
                          child: Image.network(
                            widget.item.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _kLightRed,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: _kRoseBorder,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Show discount badge if applicable
                      if (bestDiscount != null)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: DiscountBadge(discount: bestDiscount),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRIVENI STORE',
                          style: TextStyle(
                            fontSize: 8,
                            color: _kDarkRed,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${widget.item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _kRed,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '₹$mrp',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _kTextGrey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                ref.read(cartProvider.notifier).addItem(widget.item);
                HapticFeedback.lightImpact();
                setState(() => _added = true);

                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _added = false);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                    Text('${widget.item.name} added to cart!'),
                    backgroundColor: _kRed,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _added
                        ? [_kGreen, _kGreenBright]
                        : [_kDarkRed, _kRed],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_added ? _kGreen : _kRed)
                          .withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _added ? Icons.check : Icons.add,
                  color: _kWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ProductGridShimmer extends StatelessWidget {
  const _ProductGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6, // 👈 number of shimmer cards
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, __) => const _ProductCardShimmer(),
      ),
    );
  }
}


class _ProductCardShimmer extends StatelessWidget {
  const _ProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 Image shimmer
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
              ),
            ),

            // 🔥 Text + price shimmer
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 14, width: 50, color: Colors.white),
                      Container(
                        height: 28,
                        width: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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
