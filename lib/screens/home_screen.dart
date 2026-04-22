import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:math' as math;

import '../models/category.dart';
import '../models/discount.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/discount_providers.dart';
import '../providers/location_provider.dart';
import '../providers/product_providers.dart';
import '../providers/service_providers.dart';
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

// ─────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  Future<void> _logout() async {
    final auth     = ref.read(authServiceProvider);
    final cart     = ref.read(cartProvider.notifier);
    final location = ref.read(locationProvider.notifier);
    await auth.signOut();
    cart.clearCart();
    location.clear();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final locationState   = ref.watch(locationProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync      = ref.watch(itemsProvider(_selectedCategoryId));
    final cartItems       = ref.watch(cartProvider);
    final activeDiscounts = ref.watch(activeDiscountsProvider).valueOrNull ?? [];

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

        // ── FLOATING CART ──────────────────────────────────────────
        floatingActionButton: cartItems.items.isEmpty
            ? null
            : _AnimatedCartButton(itemCount: cartItems.items.length),

        body: Column(
          children: [
            // ── HEADER ────────────────────────────────────────────
            _Header(locationState: locationState, onLogout: _logout),

            // ── SEARCH BAR ────────────────────────────────────────
            _SearchBar(controller: _searchController),

            // ── SCROLLABLE BODY ───────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: _kRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // ── PROMO BANNERS ────────────────────────
                      const _PromoBanners(),

                      const SizedBox(height: 8),

                      // ── LIVE TICKER STRIP ─────────────────────
                      const _LiveTickerStrip(),

                      const SizedBox(height: 4),

                      // ── CATEGORIES (DOUBLE LAYER) ────────────
                      _SectionHeader(
                        title: 'Shop by Category',
                        onSeeAll: () => context.push('/all-products'),
                      ),
                      categoriesAsync.when(
                        loading: () => const _CategoryShimmerDouble(),
                        error: (_, __) => const SizedBox(),
                        data: (cats) => _DoubleCategoryBar(
                          categories: cats,
                          selectedId: _selectedCategoryId,
                          onSelected: (id) =>
                              setState(() => _selectedCategoryId = id),
                        ),
                      ),

                      const SizedBox(height: 3),

                      // ── PREVIOUSLY BOUGHT ────────────────────
                      _SectionHeader(
                        title: 'Previously Bought',
                        onSeeAll: () => context.push('/all-products'),
                      ),
                      itemsAsync.when(
                        loading: () => const _HorizontalShimmer(),
                        error: (_, __) => const SizedBox(),
                        data: (items) => _PreviouslyBoughtRow(
                          items: items.take(5).toList(),
                          activeDiscounts: activeDiscounts,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── MARKETING SLIDER (below Previously Bought) ───
                      const _MarketingSlider(),

                      const SizedBox(height: 10),

                      // ── YOU MIGHT NEED GRID ──────────────────
                      _SectionHeader(
                        title: 'You Might Need 🔥',
                        onSeeAll: () => context.push('/all-products'),
                      ),
                      itemsAsync.when(
                        loading: () => const _ProductShimmerGrid(),
                        error: (e, _) => _ErrorTile(
                            message: 'Failed to load items',
                            onRetry: _refresh),
                        data: (_) {
                          final displayItems = filteredItems.take(6).toList();
                          return displayItems.isEmpty
                              ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No items found',
                                  style: TextStyle(color: _kTextGrey)),
                            ),
                          )
                              : _ProductGrid(items: displayItems, activeDiscounts: activeDiscounts);
                        },
                      ),

                      const SizedBox(height: 10),

                      // ── BEST OFFERS ─────────────────────────
                      _AdImageSection(
                        title: "Best Offers",
                        ads: [
                          "assets/images/banner1.jpeg",
                          "assets/images/banner2.jpeg",
                          "assets/images/banner3.jpeg",
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── BRAND SPOTLIGHT (below Best Offers) ─
                      // const _BrandSpotlightSection(),


                      // BrandScrollSection(),
                      _ImagePromoBanners(),

                      const SizedBox(height: 10),

                      // ── FLASH DEALS SECTION ──────────────────
                      const _FlashDealsSection(),

                      const SizedBox(height: 10),

                      // ── REFERRAL CARD ────────────────────────
                      const _ReferralCard(),

                      const SizedBox(height: 80),
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

// ═════════════════════════════════════════════════════════════════
// ANIMATED CART BUTTON
// ═════════════════════════════════════════════════════════════════
class _AnimatedCartButton extends StatefulWidget {
  final int itemCount;
  const _AnimatedCartButton({required this.itemCount});

  @override
  State<_AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<_AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () => context.push('/cart'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _kRed.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, color: _kWhite, size: 20),
              const SizedBox(width: 8),
              Text(
                '${widget.itemCount} Items  |  Checkout',
                style: const TextStyle(
                    color: _kWhite, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios, color: _kWhite, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// HEADER — Upgraded Icons
// ═════════════════════════════════════════════════════════════════
// ═════════════════════════════════════════════════════════════════
// HEADER — Mirror Effect Icons
// ═════════════════════════════════════════════════════════════════
class _Header extends ConsumerWidget {
  final dynamic locationState;
  final VoidCallback onLogout;

  const _Header({required this.locationState, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(bottom: BorderSide(color: _kRoseBorder, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: _kWhite, size: 12),
                      SizedBox(width: 2),
                      Text(
                        'Triveni Smart Store',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _kTextDark,
                    ),
                    children: [
                      TextSpan(text: 'in '),
                      TextSpan(
                        text: '8 minutes',
                        style: TextStyle(color: _kRed),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: _kRed, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      locationState.address ?? 'HOME — Patna, Bihar',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: _kTextGrey, size: 16),
                  ],
                ),
              ],
            ),
          ),

          // Row(
          //   children: [
          //     // Cart button with badge
          //     if (cartState.items.isNotEmpty) ...[
          //       // _MirrorIconBtn(
          //       //   onTap: () => context.push('/cart'),
          //       //   icon: Icons.shopping_bag_rounded,
          //       //   badge: '${cartState.items.length}',
          //       //   label: 'Cart',
          //       //   baseColor: const Color(0xFFB22222),
          //       //   accentColor: const Color(0xFFDC143C),
          //       // ),
          //       const SizedBox(width: 8),
          //     ],
          //     // // Orders button
          //     // _MirrorIconBtn(
          //     //   onTap: () => context.push('/orders'),
          //     //   icon: Image.asset('assets/icons/bag_icon.png'),
          //     //   label: 'Orders',
          //     //   baseColor: Color(0xFFB22222),
          //     //   accentColor: Color(0xFFDC143C),
          //     // ),
          //
          //
          //     if (cartState.items.isNotEmpty) ...[
          //       // _MirrorIconBtn(
          //       //   onTap: () => context.push('/cart'),
          //       //   icon: Icons.shopping_bag_rounded,
          //       //   badge: '${cartState.items.length}',
          //       //   label: 'Cart',
          //       //   baseColor: const Color(0xFFB22222),
          //       //   accentColor: const Color(0xFFDC143C),
          //       // ),
          //
          //       GestureDetector(
          //         onTap: () => context.push('/cart'),
          //         child: Column(
          //           mainAxisSize: MainAxisSize.min,
          //           children: [
          //             Image.asset(
          //               'assets/images/cart.png',
          //               width: 35,
          //               height: 35,
          //               color: _kRed,
          //             ),
          //             // const Text(
          //             //   'My Cart',
          //             //   style: TextStyle(fontSize: 10,color: _kRed,fontWeight: FontWeight.bold),
          //             // ),
          //           ],
          //         ),
          //       ),
          //       const SizedBox(width: 8),
          //     ],
          //
          //
          //     GestureDetector(
          //       onTap: () => context.push('/orders'),
          //       child: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Image.asset(
          //             'assets/images/bag_icon.png',
          //             width: 40,
          //             height: 40,
          //           ),
          //           // const Text(
          //           //   'Orders',
          //           //   style: TextStyle(fontSize: 10,color: _kRed,fontWeight: FontWeight.bold),
          //           // ),
          //         ],
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     // Profile button
          //     // _MirrorIconBtn(
          //     //   onTap: () => context.push('/profile'),
          //     //   icon: Icons.person_rounded,
          //     //   label: 'Me',
          //     //   baseColor: const Color(0xFFB22222),
          //     //   accentColor: const Color(0xFFDC143C),
          //     // ),
          //
          //
          //
          //     GestureDetector(
          //       onTap: () => context.push('/profile'),
          //       child: Column(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Image.asset(
          //             'assets/images/user_img.png',
          //             width: 35,
          //             height: 35,
          //             color: _kRed,
          //           ),
          //           // const Text(
          //           //   'My Cart',
          //           //   style: TextStyle(fontSize: 10,color: _kRed,fontWeight: FontWeight.bold),
          //           // ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
          Row(
            children: [
              if (cartState.items.isNotEmpty) ...[
                _buildIconButton(
                  iconPath: 'assets/images/cart.png',
                  onTap: () => context.push('/cart'),
                  bgColor: Colors.red.shade50,
                  iconColor: Colors.red.shade600,
                ),
                const SizedBox(width: 10),
              ],

              _buildIconButton(
                iconPath: 'assets/images/bag_icon.png',
                onTap: () => context.push('/orders'),
                bgColor: Colors.blue.shade50,
                // iconColor: Colors.blue.shade600,
                size: 24,
              ),

              const SizedBox(width: 10),

              _buildIconButton(
                iconPath: 'assets/images/user_img.png',
                onTap: () => context.push('/profile'),
                bgColor: Colors.green.shade50,
                iconColor: Colors.green.shade600,
              ),
            ],
          )
        ],
      ),
    );
  }



  Widget _buildIconButton({
    required String iconPath,
    required VoidCallback onTap,
    required Color bgColor,
    Color? iconColor,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),

          // 🌈 Gradient for glossy base
          gradient: LinearGradient(
            colors: [
              bgColor.withOpacity(0.9),
              bgColor.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          // 🌫️ Soft shadow
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(3, 6),
            ),
          ],
        ),

        child: Stack(
          children: [
            // ✨ Top glossy highlight
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.35),
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),

            // 🎯 Icon
            Center(
              child: Image.asset(
                iconPath,
                width: size,
                height: size,
                color: iconColor, // null = original color
              ),
            ),
          ],
        ),
      ),
    );
  }}




// ─── Advanced Mirror Effect Icon/Image Button ───────────────────────────
class _MirrorIconBtn extends StatefulWidget {
  final Widget icon; // ✅ changed from IconData → Widget
  final String label;
  final String? badge;
  final Color baseColor;
  final Color accentColor;
  final VoidCallback? onTap;

  const _MirrorIconBtn({
    required this.icon,
    required this.label,
    required this.baseColor,
    required this.accentColor,
    this.badge,
    this.onTap,
  });

  @override
  State<_MirrorIconBtn> createState() => _MirrorIconBtnState();
}

class _MirrorIconBtnState extends State<_MirrorIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();

  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // ── Outer glow ring ──
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.baseColor.withOpacity(
                            0.12 + _shimmerAnim.value * 0.18,
                          ),
                          width: 1,
                        ),
                      ),
                    ),

                    // ── Main chrome body ──
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                          colors: [
                            _kWhite,
                            widget.baseColor.withOpacity(0.08),
                            widget.baseColor.withOpacity(0.18),
                            widget.accentColor.withOpacity(0.10),
                            _kWhite.withOpacity(0.95),
                          ],
                        ),
                        border: Border.all(
                          color: widget.baseColor.withOpacity(0.22),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.baseColor.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(2, 4),
                          ),
                          BoxShadow(
                            color: _kWhite.withOpacity(0.9),
                            blurRadius: 4,
                            spreadRadius: -2,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // ── Top shine ──
                          Positioned(
                            top: 6,
                            left: 7,
                            child: Container(
                              width: 14,
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  colors: [
                                    _kWhite.withOpacity(0.75),
                                    _kWhite.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Bottom reflection strip ──
                          Positioned(
                            bottom: 7,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    widget.accentColor.withOpacity(0.0),
                                    widget.accentColor.withOpacity(0.20),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Image + Mirror ──
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: widget.icon,
                              ),

                              Transform(
                                alignment: Alignment.topCenter,
                                transform: Matrix4.identity()..scale(1.0, -1.0),
                                child: ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.30),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ).createShader(bounds),
                                  child: SizedBox(
                                    height: 10,
                                    width: 10,
                                    child: Opacity(
                                      opacity: 0.35,
                                      child: widget.icon,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Badge ──
                    if (widget.badge != null)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.baseColor, widget.accentColor],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: _kWhite, width: 1.5),
                          ),
                          constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            widget.badge!,
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

                const SizedBox(height: 3),

                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [widget.baseColor, widget.accentColor],
                  ).createShader(bounds),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
// ═════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kLightRed,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kRoseBorder, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: _kTextDark),
          decoration: const InputDecoration(
            hintText: 'Search "dal, rice, biscuits..."',
            hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: _kDarkRed, size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// LIVE TICKER STRIP
// ═════════════════════════════════════════════════════════════════
class _LiveTickerStrip extends StatefulWidget {
  const _LiveTickerStrip();

  @override
  State<_LiveTickerStrip> createState() => _LiveTickerStripState();
}

class _LiveTickerStripState extends State<_LiveTickerStrip> {
  final ScrollController _sc = ScrollController();
  Timer? _timer;

  static const _messages = [
    '🎉 10% OFF on first order — use TRIVENI10',
    '🚀 Free delivery above ₹149',
    '🥦 Fresh veggies added daily',
    '💳 Pay with UPI & get cashback',
    '⚡ Lightning-fast 8-min delivery',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_sc.hasClients) return;
      final max = _sc.position.maxScrollExtent;
      if (_sc.offset >= max) {
        _sc.jumpTo(0);
      } else {
        _sc.animateTo(_sc.offset + 1.2,
            duration: const Duration(milliseconds: 30),
            curve: Curves.linear);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _messages.join('     ✦     ') + '     ✦     ';
    return Container(
      color: _kDarkRed,
      height: 32,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: _kRed,
            child: const Row(
              children: [
                Icon(Icons.campaign_rounded, color: _kWhite, size: 14),
                SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: _kWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  text,
                  style: const TextStyle(
                      color: _kWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PROMO BANNERS
// ═════════════════════════════════════════════════════════════════
class _PromoBanners extends StatefulWidget {
  const _PromoBanners();

  @override
  State<_PromoBanners> createState() => _PromoBannersState();
}

class _PromoBannersState extends State<_PromoBanners> {
  final PageController _pc =
  PageController(viewportFraction: 0.80, initialPage: 0);
  int _page = 0;

  static const List<_BannerData> _banners = [
    _BannerData(
      gradient: [Color(0xFFB22222), Color(0xFFDC143C)],
      badge: 'NEW ARRIVAL',
      title: 'Triveni\nStore',
      sub: 'Everything for you 🛍️',
      emoji: '🏬',
    ),
    _BannerData(
      gradient: [Color(0xFFE65100), Color(0xFFFF6D00)],
      badge: 'LIMITED OFFER',
      title: '10% OFF\nFirst Order',
      sub: 'Use code: TRIVENI10 🎁',
      emoji: '🎉',
    ),
    _BannerData(
      gradient: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
      badge: 'TRENDING',
      title: 'Summer\nEssentials',
      sub: 'Stay cool ☀️',
      emoji: '🕶️',
    ),
    _BannerData(
      gradient: [Color(0xFF2E7D32), Color(0xFF43A047)],
      badge: 'FRESH DAILY',
      title: 'Farm Fresh\nVeggies',
      sub: 'Direct from farm 🌱',
      emoji: '🥦',
    ),
    _BannerData(
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
      badge: 'BEST SELLER',
      title: 'Daily\nGroceries',
      sub: 'Save more everyday 🛒',
      emoji: '🧺',
    ),
    _BannerData(
      gradient: [Color(0xFFAD1457), Color(0xFFE91E63)],
      badge: 'BEAUTY DEALS',
      title: 'Glow Up\nSale',
      sub: 'Look fresh ✨',
      emoji: '💄',
    ),
    _BannerData(
      gradient: [Color(0xFF37474F), Color(0xFF607D8B)],
      badge: 'FAST DELIVERY',
      title: '30 Min\nDelivery',
      sub: 'Quick doorstep 🚚',
      emoji: '⚡',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final next = (_page + 1) % _banners.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _pc,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return AnimatedScale(
                scale: _page == i ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: b.gradient.last.withOpacity(0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 40,
                        bottom: -30,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.badge,
                                style: const TextStyle(
                                    color: _kWhite,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.title,
                              style: const TextStyle(
                                color: _kWhite,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(b.sub,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 8,
                        child: Text(b.emoji,
                            style: const TextStyle(fontSize: 42)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _kRed : _kRoseBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

@immutable
class _BannerData {
  final List<Color> gradient;
  final String badge;
  final String title;
  final String sub;
  final String emoji;

  const _BannerData({
    required this.gradient,
    required this.badge,
    required this.title,
    required this.sub,
    required this.emoji,
  });
}

// ═════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════




class _ImagePromoBanners extends StatefulWidget {
  const _ImagePromoBanners();

  @override
  State<_ImagePromoBanners> createState() => _ImagePromoBannersState();
}

class _ImagePromoBannersState extends State<_ImagePromoBanners> {
  final PageController _pc =
  PageController(viewportFraction: 0.80, initialPage: 0);
  int _page = 0;

  static const List<_ImageBannerData> _banners = [
    _ImageBannerData(image: 'assets/images/banner5.jpeg'),
    _ImageBannerData(image: 'assets/images/banner6.jpeg'),
    _ImageBannerData(image: 'assets/images/banner7.jpeg'),
    _ImageBannerData(image: 'assets/images/banner8.jpeg'),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final next = (_page + 1) % _banners.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(title: "Daily Needs", onSeeAll: null),
        SizedBox(height: 4,),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pc,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return AnimatedScale(
                scale: _page == i ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    b.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _kRed : _kRoseBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

@immutable
class _ImageBannerData {
  final String image;

  const _ImageBannerData({
    required this.image,
  });
}
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllText;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    this.seeAllText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDarkRed, _kRed],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark)),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRoseBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Text(
                      seeAllText ?? 'See All',
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kRed,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios, color: _kRed, size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// DOUBLE LAYER CATEGORY BAR
// ═════════════════════════════════════════════════════════════════
class _DoubleCategoryBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _DoubleCategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [
      _CategoryItem(id: null, name: 'All',
          imageUrl: 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png'),
      ...categories.map((c) => _CategoryItem(id: c.id, name: c.name, imageUrl: c.imageUrl)),
    ];

    // Split into 2 rows
    final half = (allItems.length / 2).ceil();
    final row1 = allItems.sublist(0, half);
    final row2 = allItems.sublist(half);

    return SizedBox(
      height: 206, // Two rows
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1
            Row(
              children: row1.map((item) => _CategoryChipNew(
                label: item.name,
                imageUrl: item.imageUrl,
                selected: selectedId == item.id,
                onTap: () => onSelected(item.id),
              )).toList(),
            ),
            const SizedBox(height: 10),
            // Row 2
            Row(
              children: row2.map((item) => _CategoryChipNew(
                label: item.name,
                imageUrl: item.imageUrl,
                selected: selectedId == item.id,
                onTap: () => onSelected(item.id),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String? id;
  final String name;
  final String imageUrl;
  const _CategoryItem({required this.id, required this.name, required this.imageUrl});
}

class _CategoryChipNew extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChipNew({
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
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kLightRed : _kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kRed : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _kRed.withOpacity(0.2)
                  : Colors.black.withOpacity(0.06),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kRed.withOpacity(0.1) : Colors.grey.shade100,
                border: selected
                    ? Border.all(color: _kRed.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.category, size: 22, color: selected ? _kRed : _kTextGrey),
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
                fontSize: 9.5,
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
// PREVIOUSLY BOUGHT
// ═════════════════════════════════════════════════════════════════
class _PreviouslyBoughtRow extends StatelessWidget {
  final List<Item> items;
  final List<Discount> activeDiscounts;

  const _PreviouslyBoughtRow({required this.items, required this.activeDiscounts});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: items.length,
        itemBuilder: (_, i) => _PrevCard(
          item: items[i],
          activeDiscounts: activeDiscounts,
        ),
      ),
    );
  }
}

class _PrevCard extends ConsumerWidget {
  final Item item;
  final List<Discount> activeDiscounts;

  const _PrevCard({required this.item, required this.activeDiscounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestDiscount = const DiscountEngine().bestDiscount(item, activeDiscounts);

    return GestureDetector(
      onTap: () => context.push('/item/${item.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 2),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRoseBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x10B22222), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  Container(
                    height: 88,
                    width: double.infinity,
                    color: _kLightRed,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: _kRoseBorder,
                          size: 36),
                    ),
                  ),
                  if (bestDiscount != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: DiscountBadge(discount: bestDiscount),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: _kGreenBright, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('1 kg',
                          style: TextStyle(fontSize: 9, color: _kTextGrey)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: const [
                      Icon(Icons.star, color: Color(0xFFFF8F00), size: 10),
                      Icon(Icons.star, color: Color(0xFFFF8F00), size: 10),
                      Icon(Icons.star, color: Color(0xFFFF8F00), size: 10),
                      Icon(Icons.star, color: Color(0xFFFF8F00), size: 10),
                      Icon(Icons.star_half, color: Color(0xFFFF8F00), size: 10),
                      SizedBox(width: 3),
                      Text('(12,341)',
                          style: TextStyle(fontSize: 8, color: Color(0xFFFF8F00))),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _kTextDark),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            ref.read(cartProvider.notifier).addItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kDarkRed, _kRed]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ADD',
                              style: TextStyle(
                                  color: _kWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
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
// MARKETING SLIDER (below Previously Bought)
// ═════════════════════════════════════════════════════════════════
class _MarketingSlider extends StatefulWidget {
  const _MarketingSlider();

  @override
  State<_MarketingSlider> createState() => _MarketingSliderState();
}

class _MarketingSliderState extends State<_MarketingSlider> {
  final PageController _pc = PageController();
  int _page = 0;

  static const _cards = [
    _MktCard(
      gradient: [Color(0xFF1A237E), Color(0xFF283593)],
      title: 'Pay with UPI',
      subtitle: 'Get ₹20 cashback every order',
      icon: '💸',
      tag: 'CASHBACK',
    ),
    _MktCard(
      gradient: [Color(0xFF880E4F), Color(0xFFC2185B)],
      title: 'Refer & Earn',
      subtitle: 'Invite friends, earn ₹50 each',
      icon: '🎁',
      tag: 'REWARDS',
    ),
    _MktCard(
      gradient: [Color(0xFF004D40), Color(0xFF00796B)],
      title: 'Triveni Gold',
      subtitle: 'Unlock unlimited free delivery',
      icon: '👑',
      tag: 'MEMBERSHIP',
    ),
    _MktCard(
      gradient: [Color(0xFFE65100), Color(0xFFF57C00)],
      title: 'Morning Magic',
      subtitle: 'Order by 8 AM, delivered by 9 AM',
      icon: '🌅',
      tag: 'EARLY BIRD',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final next = (_page + 1) % _cards.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _autoSlide();
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _pc,
            itemCount: _cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final c = _cards[i];
              return AnimatedOpacity(
                opacity: _page == i ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: c.gradient.last.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative element
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text(c.icon, style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c.tag,
                                        style: const TextStyle(
                                            color: _kWhite,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.title,
                                      style: const TextStyle(
                                          color: _kWhite,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900)),
                                  Text(c.subtitle,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30, width: 1),
                              ),
                              child: const Text(
                                'Claim →',
                                style: TextStyle(
                                    color: _kWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? _kRed : _kRoseBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

@immutable
class _MktCard {
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String icon;
  final String tag;

  const _MktCard({
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
  });
}

// ═════════════════════════════════════════════════════════════════
// PRODUCT GRID
// ═════════════════════════════════════════════════════════════════
class _ProductGrid extends StatelessWidget {
  final List<Item> items;
  final List<Discount> activeDiscounts;

  const _ProductGrid({required this.items, required this.activeDiscounts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            _ItemCard(item: items[i], activeDiscounts: activeDiscounts),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ITEM CARD
// ═════════════════════════════════════════════════════════════════
class _ItemCard extends ConsumerStatefulWidget {
  final Item item;
  final List<Discount> activeDiscounts;

  const _ItemCard({required this.item, required this.activeDiscounts});

  @override
  ConsumerState<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<_ItemCard> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final mrp = (widget.item.price * 1.2).toStringAsFixed(0);
    final bestDiscount =
    const DiscountEngine().bestDiscount(widget.item, widget.activeDiscounts);

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
                            top: Radius.circular(16)),
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
                                  size: 40),
                            ),
                          ),
                        ),
                      ),
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
                    content: Text('${widget.item.name} added to cart!'),
                    backgroundColor: _kRed,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                      color: (_added ? _kGreen : _kRed).withOpacity(0.4),
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

// ═════════════════════════════════════════════════════════════════
// BEST OFFERS AD IMAGE SECTION
// ═════════════════════════════════════════════════════════════════
class _AdImageSection extends StatelessWidget {
  final String title;
  final List<String> ads;

  const _AdImageSection({required this.title, required this.ads});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onSeeAll: null),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            itemBuilder: (context, index) {
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(ads[index], fit: BoxFit.cover),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BRAND SPOTLIGHT SECTION (below Best Offers)
// ═════════════════════════════════════════════════════════════════





class BrandScrollSection extends StatelessWidget {
  const BrandScrollSection({super.key});

  // 👉 Add your banner images here
  static const List<String> banners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
    'assets/images/banner4.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Section Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '🔥 Featured',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 Horizontal Image Scroll
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 10),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),

                  // ✅ Simple shadow (optional)
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],

                  image: DecorationImage(
                    image: AssetImage(banners[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
class _BrandSpotlightSection extends StatefulWidget {
  const _BrandSpotlightSection();

  @override
  State<_BrandSpotlightSection> createState() => _BrandSpotlightSectionState();
}

class _BrandSpotlightSectionState extends State<_BrandSpotlightSection> {
  final PageController _pc = PageController(viewportFraction: 0.88);
  int _page = 0;

  static const _brands = [
    _BrandCard(
      name: 'Maggi',
      tagline: 'India\'s Favourite Noodles',
      emoji: '🍜',
      color1: Color(0xFFFFD600),
      color2: Color(0xFFFFA000),
      offer: 'Buy 2 Get 1 FREE',
    ),
    _BrandCard(
      name: 'Amul',
      tagline: 'Taste of India',
      emoji: '🧈',
      color1: Color(0xFF1565C0),
      color2: Color(0xFF1976D2),
      offer: '15% OFF today only',
    ),
    _BrandCard(
      name: 'Parle-G',
      tagline: 'G for Genius',
      emoji: '🍪',
      color1: Color(0xFF558B2F),
      color2: Color(0xFF7CB342),
      offer: 'Bundle deal available',
    ),
    _BrandCard(
      name: 'Haldiram',
      tagline: 'Authentic Indian Snacks',
      emoji: '🥜',
      color1: Color(0xFF6A1B9A),
      color2: Color(0xFF8E24AA),
      offer: '₹30 OFF on ₹200',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _autoSlide();
  }

  void _autoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_page + 1) % _brands.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _autoSlide();
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeader(title: '🏆 Brand Spotlight', onSeeAll: null),
        const SizedBox(height: 6),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pc,
            itemCount: _brands.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _brands[i];
              return AnimatedScale(
                scale: _page == i ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [b.color1, b.color2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: b.color2.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Big emoji brand logo
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(b.emoji,
                                style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(b.name,
                                  style: const TextStyle(
                                      color: _kWhite,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(b.tagline,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(b.offer,
                                    style: TextStyle(
                                        color: b.color1,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_brands.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? _kRed : _kRoseBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

@immutable
class _BrandCard {
  final String name;
  final String tagline;
  final String emoji;
  final Color color1;
  final Color color2;
  final String offer;

  const _BrandCard({
    required this.name,
    required this.tagline,
    required this.emoji,
    required this.color1,
    required this.color2,
    required this.offer,
  });
}

// ═════════════════════════════════════════════════════════════════
// FLASH DEALS SECTION (horizontal card strip)
// ═════════════════════════════════════════════════════════════════
class _FlashDealsSection extends StatefulWidget {
  const _FlashDealsSection();

  @override
  State<_FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<_FlashDealsSection> {
  // Countdown timer
  late Timer _timer;
  int _seconds = 3600; // 1 hour

  static const _deals = [
    _DealCard(emoji: '🥚', name: 'Farm Eggs', originalPrice: 80, dealPrice: 60, tag: 'HOT'),
    _DealCard(emoji: '🍌', name: 'Banana', originalPrice: 50, dealPrice: 30, tag: 'FRESH'),
    _DealCard(emoji: '🧴', name: 'Shampoo', originalPrice: 220, dealPrice: 160, tag: 'DEAL'),
    _DealCard(emoji: '🌾', name: 'Basmati Rice', originalPrice: 180, dealPrice: 140, tag: 'SAVE'),
    _DealCard(emoji: '🫙', name: 'Pickle Jar', originalPrice: 120, dealPrice: 89, tag: 'HOT'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = math.max(0, _seconds - 1));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeStr {
    final h = _seconds ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with countdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kDarkRed, _kRed],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '⚡ Flash Deals',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kDarkRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: _kWhite, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _timeStr,
                      style: const TextStyle(
                          color: _kWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _deals.length,
            itemBuilder: (_, i) => _FlashDealCard(deal: _deals[i]),
          ),
        ),
      ],
    );
  }
}

@immutable
class _DealCard {
  final String emoji;
  final String name;
  final int originalPrice;
  final int dealPrice;
  final String tag;

  const _DealCard({
    required this.emoji,
    required this.name,
    required this.originalPrice,
    required this.dealPrice,
    required this.tag,
  });
}

class _FlashDealCard extends StatelessWidget {
  final _DealCard deal;

  const _FlashDealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final pct = (((deal.originalPrice - deal.dealPrice) / deal.originalPrice) * 100).round();

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 2),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kRoseBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x10B22222), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(deal.emoji,
                          style: const TextStyle(fontSize: 34))),
                ),
                const SizedBox(height: 6),
                Text(deal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('₹${deal.dealPrice}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _kRed)),
                    const SizedBox(width: 4),
                    Text('₹${deal.originalPrice}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: _kTextGrey,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient:
                const LinearGradient(colors: [_kDarkRed, _kRed]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$pct% OFF',
                  style: const TextStyle(
                      color: _kWhite,
                      fontSize: 8,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// REFERRAL CARD
// ═════════════════════════════════════════════════════════════════
class _ReferralCard extends StatelessWidget {
  const _ReferralCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kRed.withOpacity(0.4), width: 1),
                  ),
                  child: const Text('REFER & EARN',
                      style: TextStyle(
                          color: _kRed,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8)),
                ),
                const SizedBox(height: 8),
                const Text('Invite friends,\nearn ₹50 each!',
                    style: TextStyle(
                        color: _kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2)),
                const SizedBox(height: 6),
                Text('Share your code & both of you win',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Share Code →',
                    style: TextStyle(
                        color: _kWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text('🎁', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ERROR TILE
// ═════════════════════════════════════════════════════════════════
class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: _kRed, size: 40),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: _kTextMid)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: _kRed),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}




// ═════════════════════════════════════════════════════════════════
// SHIMMERS
// ═════════════════════════════════════════════════════════════════
class _CategoryShimmerDouble extends StatelessWidget {
  const _CategoryShimmerDouble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 206,
      child: Column(
        children: [
          _shimmerRow(),
          const SizedBox(height: 10),
          _shimmerRow(),
        ],
      ),
    );
  }

  Widget _shimmerRow() {
    return SizedBox(
      height: 93,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 6,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 78,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductShimmerGrid extends StatelessWidget {
  const _ProductShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalShimmer extends StatelessWidget {
  const _HorizontalShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 5,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}


