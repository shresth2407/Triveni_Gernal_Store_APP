# Search Feature Implementation Guide

## Overview
Add search functionality to Product Manager and Discount Manager screens in the admin app.

## Changes Required

### 1. Product Manager Screen (`lib/screens/admin/product_manager_screen.dart`)

#### Convert to StatefulWidget
```dart
class ProductManagerScreen extends ConsumerStatefulWidget {
  const ProductManagerScreen({super.key});

  @override
  ConsumerState<ProductManagerScreen> createState() => _ProductManagerScreenState();
}

class _ProductManagerScreenState extends ConsumerState<ProductManagerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
```

#### Add Search Bar (after SliverAppBar, before body content)
```dart
// ─── SEARCH BAR ─────────────────────────────────────────
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
    child: TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(fontSize: 14, color: _kTextGrey, fontWeight: FontWeight.w500),
        prefixIcon: const Icon(Icons.search_rounded, color: _kRed, size: 22),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: _kTextGrey, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: _kWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kRoseBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kRoseBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kRed, width: 2),
        ),
      ),
    ),
  ),
),
```

#### Filter Products in data callback
```dart
data: (products) {
  // Filter products based on search query
  final filteredProducts = _searchQuery.isEmpty
      ? products
      : products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

  if (products.isEmpty) {
    return const _EmptyProductsCard();
  }

  if (filteredProducts.isEmpty) {
    return _NoResultsCard(searchQuery: _searchQuery);
  }

  // Use filteredProducts instead of products in the rest of the code
  return categoriesAsync.when(
    // ... rest of code using filteredProducts
  );
}
```

#### Add No Results Widget
```dart
class _NoResultsCard extends StatelessWidget {
  final String searchQuery;
  const _NoResultsCard({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kRoseBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRoseBorder, width: 2),
                ),
                child: const Icon(Icons.search_off_rounded, size: 40, color: _kRoseBorder),
              ),
              const SizedBox(height: 20),
              const Text('No Products Found', style: TextStyle(color: _kTextDark, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('No results for "$searchQuery"', textAlign: TextAlign.center, style: const TextStyle(color: _kTextGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Discount Manager Screen (`lib/screens/admin/discount_manager_screen.dart`)

Apply the same pattern:

1. Convert to `ConsumerStatefulWidget`
2. Add `_searchController` and `_searchQuery` state
3. Add search bar after SliverAppBar
4. Filter discounts by name:
```dart
final filteredDiscounts = _searchQuery.isEmpty
    ? discounts
    : discounts.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();
```
5. Also filter by target product/category name for better UX
6. Add `_NoResultsCard` widget

#### Enhanced Discount Search (searches discount name AND product/category name)
```dart
data: (discounts) {
  // Get products and categories for enhanced search
  final productsAsync = ref.watch(adminProductsProvider);
  final categoriesAsync = ref.watch(adminCategoriesProvider);

  final filteredDiscounts = _searchQuery.isEmpty
      ? discounts
      : discounts.where((discount) {
          // Search by discount name
          if (discount.name.toLowerCase().contains(_searchQuery)) {
            return true;
          }

          // Search by target product/category name
          if (discount.scope == DiscountScope.product) {
            return productsAsync.maybeWhen(
              data: (products) {
                final product = products.where((p) => p.id == discount.targetId).firstOrNull;
                return product?.name.toLowerCase().contains(_searchQuery) ?? false;
              },
              orElse: () => false,
            );
          } else {
            return categoriesAsync.maybeWhen(
              data: (categories) {
                final category = categories.where((c) => c.id == discount.targetId).firstOrNull;
                return category?.name.toLowerCase().contains(_searchQuery) ?? false;
              },
              orElse: () => false,
            );
          }
        }).toList();

  // Rest of the code using filteredDiscounts
}
```

## Testing Checklist

- [ ] Search bar appears below app bar in both screens
- [ ] Typing filters results in real-time
- [ ] Clear button (X) appears when search has text
- [ ] Clear button clears search and shows all items
- [ ] Empty state shows when no results found
- [ ] Search is case-insensitive
- [ ] Discount search finds by discount name
- [ ] Discount search finds by product/category name
- [ ] Search persists when scrolling
- [ ] Search resets when navigating away and back

## UI/UX Notes

- Search bar has red accent color matching app theme
- Search icon on left, clear icon on right
- Rounded corners (16px) matching other inputs
- White background with rose border
- Placeholder text: "Search products..." / "Search discounts..."
- Smooth real-time filtering (no search button needed)
- Shows count of filtered results
- "No results" state with search icon and helpful message
