import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Added for Timer/Stream functionality

import '../models/category.dart';
import '../models/item.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/product_providers.dart';
import '../providers/service_providers.dart';

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

  // ─── NEW: State for "See All" functionality ───────────────────────
  bool _isViewingAllYouMightNeed = false;

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

  // ─── NEW: Toggle function for See All ─────────────────────────────
  void _toggleYouMightNeed() {
    setState(() {
      _isViewingAllYouMightNeed = !_isViewingAllYouMightNeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState   = ref.watch(locationProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync      = ref.watch(itemsProvider(_selectedCategoryId));
    final cartItems       = ref.watch(cartProvider);

    // Filter Logic (Backend untouched, only client-side filtering)
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
            : GestureDetector(
          onTap: () => context.push('/cart'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kDarkRed, _kRed]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _kRed.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: _kWhite, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${cartItems.items.length} Items  |  Checkout',
                  style: const TextStyle(
                      color: _kWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),

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

                      const SizedBox(height: 4),

                      // ── CATEGORIES ──────────────────────────
                      _SectionHeader(title: 'Shop by Category', onSeeAll: () {}),
                      categoriesAsync.when(
                        loading: () => const SizedBox(
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(color: _kRed),
                          ),
                        ),
                        error: (_, __) => const SizedBox(),
                        data: (cats) => _CategoryBar(
                          categories: cats,
                          selectedId: _selectedCategoryId,
                          onSelected: (id) =>
                              setState(() => _selectedCategoryId = id),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── PREVIOUSLY BOUGHT ────────────────────
                      _SectionHeader(title: 'Previously Bought', onSeeAll: () {}),
                      itemsAsync.when(
                        loading: () => const SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(color: _kRed),
                          ),
                        ),
                        error: (_, __) => const SizedBox(),
                        data: (items) => _PreviouslyBoughtRow(
                          items: items.take(5).toList(),
                        ),
                      ),

                      const SizedBox(height: 3),

                      // ── YOU MIGHT NEED GRID (UPDATED LOGIC) ──────────────────
                      // Use dynamic text for See All / Show Less
                      _SectionHeader(
                        title: 'You Might Need 🔥',
                        onSeeAll: _toggleYouMightNeed,
                        seeAllText: _isViewingAllYouMightNeed ? 'Show Less' : 'See All',
                      ),
                      itemsAsync.when(
                          loading: () => const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(color: _kRed),
                            ),
                          ),
                          error: (e, _) => _ErrorTile(
                              message: 'Failed to load items',
                              onRetry: _refresh),
                          data: (_) {
                            // LOGIC: Take only 6 if not expanded, else show all
                            final displayItems = _isViewingAllYouMightNeed
                                ? filteredItems
                                : filteredItems.take(6).toList();

                            return displayItems.isEmpty
                                ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('No items found',
                                    style: TextStyle(color: _kTextGrey)),
                              ),
                            )
                                : _ProductGrid(items: displayItems);
                          }
                      ),

                      const SizedBox(height: 1),

                      // ── FREE DELIVERY BANNER ─────────────────
                      const _FreeDeliveryBanner(),

                      // ── NEW: ADVERTISEMENT SECTIONS ───────────────────────
                      const SizedBox(height: 5),
                      const _AdSection(
                        title: 'Bank Offers 💳',
                        ads: _AdData.bankOffers,
                      ),
                      const SizedBox(height: 5),
                      const _AdSection(
                        title: 'Weekend Sale 🎉',
                        ads: _AdData.weekendSale,
                      ),

                      const SizedBox(height: 50),
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
// HEADER (FIXED: Removed duplicate color property)
// ═════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final dynamic locationState;
  final VoidCallback onLogout;

  const _Header({required this.locationState, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 16,
        right: 16,
        bottom: 10,
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
                        'Triveni Express',
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
                    const Icon(Icons.arrow_drop_down,
                        color: _kTextGrey, size: 16),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CircleBtn(
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('₹',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kDarkRed,
                            fontWeight: FontWeight.w800)),
                    Text('₹0',
                        style: TextStyle(
                            fontSize: 7,
                            color: _kDarkRed,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CircleBtn(
                onTap: onLogout,
                child: const Icon(Icons.person, color: _kDarkRed, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kLightRed,
          shape: BoxShape.circle,
          border: Border.all(color: _kRoseBorder, width: 1.5),
        ),
        child: child,
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
          decoration: InputDecoration(
            hintText: 'Search "dal, rice, biscuits..."',
            hintStyle:
            const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _kDarkRed, size: 22),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic, color: _kWhite, size: 18),
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          ),
        ),
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
      badge: 'NEWLY LAUNCHED',
      title: 'Triveni\nStore',
      sub: 'For You ✦',
      emoji: '🛒',
    ),
    _BannerData(
      gradient: [Color(0xFFE65100), Color(0xFFFF6D00)],
      badge: 'FEATURED',
      title: '10% OFF\nFirst Order',
      sub: 'Use code: TRIVENI10',
      emoji: '🎉',
    ),
    _BannerData(
      gradient: [Color(0xFFAD1457), Color(0xFFE91E63)],
      badge: 'FEATURED',
      title: 'Summer\nGlow Up',
      sub: 'Stay cool this season',
      emoji: '🌸',
    ),
    _BannerData(
      gradient: [Color(0xFF2E7D32), Color(0xFF43A047)],
      badge: 'FRESH DAILY',
      title: 'Farm-Fresh\nVeggies',
      sub: 'Farm to door 🌱',
      emoji: '🥦',
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
          height: 114,
          child: PageView.builder(
            controller: _pc,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final b = _banners[i];
              return AnimatedScale(
                scale: _page == i ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: b.gradient.last.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                                    letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              b.title,
                              style: const TextStyle(
                                color: _kWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(b.sub,
                                style: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.85),
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 6,
                        child: Text(b.emoji,
                            style: const TextStyle(fontSize: 38)),
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
          children: List.generate(_banners.length, (i) {
            final active = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
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
// SECTION HEADER (UPDATED: Support dynamic text)
// ═════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllText; // New parameter

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
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllText ?? 'See All →',
                style: const TextStyle(
                    fontSize: 12,
                    color: _kRed,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CATEGORY BAR
// ═════════════════════════════════════════════════════════════════
class _CategoryBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'All',
            imageUrl:
            'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          ...categories.map((c) => _CategoryChip(
            label: c.name,
            imageUrl: c.imageUrl,
            selected: selectedId == c.id,
            onTap: () => onSelected(c.id),
          )),
        ],
      ),
    );
  }
}

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
        width: 72,
        margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: selected ? _kLightRed : _kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kRed : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _kRed.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
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
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
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

  const _PreviouslyBoughtRow({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return SizedBox(
      height: 215,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) => _PrevCard(item: items[i]),
      ),
    );
  }
}

class _PrevCard extends ConsumerWidget {
  final Item item;

  const _PrevCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mrp = (item.price * 1.3).toStringAsFixed(0);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, bottom: 4, top: 2),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRoseBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10B22222),
              blurRadius: 8,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
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
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: _kWhite.withOpacity(0.85),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border,
                        color: _kRed, size: 15),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
                        style:
                        TextStyle(fontSize: 9, color: _kTextGrey)),
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
                    Icon(Icons.star_half,
                        color: Color(0xFFFF8F00), size: 10),
                    SizedBox(width: 3),
                    Text('(12,341)',
                        style: TextStyle(
                            fontSize: 8, color: Color(0xFFFF8F00))),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _kTextDark),
                        ),
                        Row(
                          children: [
                            Text('₹$mrp',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: _kTextGrey,
                                    decoration:
                                    TextDecoration.lineThrough)),
                            const SizedBox(width: 4),
                            const Text('23% OFF',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: _kGreen,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
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
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// PRODUCT GRID (UPDATED: Dynamic Item Count)
// ═════════════════════════════════════════════════════════════════
class _ProductGrid extends StatelessWidget {
  final List<Item> items;

  const _ProductGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length, // Uses the length passed from parent (6 or all)
          itemBuilder: (_, i) => _ItemCard(item: items[i]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ITEM CARD
// ═════════════════════════════════════════════════════════════════
class _ItemCard extends ConsumerStatefulWidget {
  final Item item;

  const _ItemCard({required this.item});

  @override
  ConsumerState<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<_ItemCard> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    final mrp = (widget.item.price * 1.2).toStringAsFixed(0);

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
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kDarkRed, _kRed],
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(
                              color: _kWhite,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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

// ═════════════════════════════════════════════════════════════════
// FREE DELIVERY BANNER
// ═════════════════════════════════════════════════════════════════
class _FreeDeliveryBanner extends StatefulWidget {
  const _FreeDeliveryBanner();

  @override
  State<_FreeDeliveryBanner> createState() =>
      _FreeDeliveryBannerState();
}

class _FreeDeliveryBannerState extends State<_FreeDeliveryBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kLightRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRoseBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('🛵', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Get FREE delivery',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kRed)),
                Text('on your order above ₹149 →',
                    style:
                    TextStyle(fontSize: 11, color: _kTextGrey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _visible = false),
            child: const Icon(Icons.close,
                size: 18, color: _kTextGrey),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// NEW: ADVERTISEMENT SECTION
// ═════════════════════════════════════════════════════════════════
class _AdData {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String emoji;

  const _AdData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.emoji,
  });

  static const List<_AdData> bankOffers = [
    _AdData(
      title: 'HDFC Bank',
      subtitle: '10% Instant Discount',
      gradient: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      emoji: '💳',
    ),
    _AdData(
      title: 'ICICI Net Banking',
      subtitle: 'Up to ₹100 Off',
      gradient: [Color(0xFFFFD600), Color(0xFFFFAB00)],
      emoji: '🏦',
    ),
  ];

  static const List<_AdData> weekendSale = [
    _AdData(
      title: 'Mega Weekend Sale',
      subtitle: 'Flat 50% OFF on Snacks',
      gradient: [Color(0xFF880E4F), Color(0xFFC2185B)],
      emoji: '🔥',
    ),
    _AdData(
      title: 'Healthy Choice',
      subtitle: 'Buy 1 Get 1 Free',
      gradient: [Color(0xFF33691E), Color(0xFF689F38)],
      emoji: '🥗',
    ),
  ];
}

class _AdSection extends StatelessWidget {
  final String title;
  final List<_AdData> ads;

  const _AdSection({required this.title, required this.ads});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, onSeeAll: null),
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ad.gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ad.gradient.last.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ad.title,
                              style: const TextStyle(
                                color: _kWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ad.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ad.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ],
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
            Text(message,
                style: const TextStyle(color: _kTextMid)),
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