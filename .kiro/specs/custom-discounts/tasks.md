# Implementation Plan: Custom Discounts

## Overview

Add a first-class promotions system to the Flutter grocery delivery app. Tasks are ordered foundationally: the `Discount` model first, then the pure `DiscountEngine`, then the Firestore service, Riverpod providers, cart integration, shared widget, admin screen, routing, and finally customer-facing UI screens. All discount code is purely additive — no existing files are deleted.

## Tasks

- [x] 1. Create `Discount` model in `lib/models/discount.dart`
  - Define `DiscountType` enum (`percentage`, `bogo`, `bulk`) and `DiscountScope` enum (`product`, `category`)
  - Implement `Discount` class with all required fields: `id`, `name`, `type`, `scope`, `targetId`, `isActive`, `createdAt`, and type-specific nullable fields (`value`, `buyQty`, `freeQty`, `minQty`, `discountPercent`)
  - Implement `Discount.fromFirestore(DocumentSnapshot)` factory reading all fields defined in Requirement 1.1–1.4
  - Implement `toFirestore()` method that omits null type-specific fields from the output map
  - Export `Discount`, `DiscountType`, `DiscountScope` from `lib/models/models.dart`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 10.1, 10.2_

  - [ ]* 1.1 Write property test for serialization round-trip (Property 1)
    - **Property 1: Serialization round-trip**
    - Generate random valid `Discount` objects of all three types → `toFirestore()` → `Discount.fromFirestore` → assert all fields equal
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 10.3**

- [x] 2. Implement `DiscountEngine` in `lib/services/discount_engine.dart`
  - Implement pure `DiscountEngine` class with no Firestore dependency
  - `bestDiscount(Item item, List<Discount> activeDiscounts)` — filters by scope/targetId match, returns the discount producing the lowest line total, or `null` if none match
  - `computeLineTotal(CartItem cartItem, List<Discount> activeDiscounts)` — applies best-discount-wins logic using the formulas in Requirements 5.3–5.6 and 5.8; returns `price × quantity` when list is empty or no discount matches
  - `compute(List<CartItem> items, List<Discount> activeDiscounts)` — returns a `DiscountedCart` with `lines`, `subtotal`, `totalSavings`, and `grandTotal`
  - Define `DiscountedCart` and `DiscountedLine` value objects in the same file
  - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10_

  - [ ] 2.1 Write property test for percentage discount formula (Property 9)
    - **Property 9: Percentage discount formula**
    - Generate random `P`, `Q`, `V` → assert `computeLineTotal == P * (1 - V/100) * Q`
    - **Validates: Requirements 5.3**

  - [ ]* 2.2 Write property test for BOGO discount formula (Property 10)
    - **Property 10: BOGO discount formula**
    - Generate random `P`, `Q`, `B`, `F` → assert `computeLineTotal == payable * P` where `payable = (Q ~/ (B+F)) * B + (Q % (B+F))`
    - **Validates: Requirements 5.4**

  - [ ]* 2.3 Write property test for bulk discount threshold behavior (Property 11)
    - **Property 11: Bulk discount threshold behavior**
    - Generate random `P`, `Q`, `M`, `D` → when `Q >= M` assert discounted formula; when `Q < M` assert `P * Q`
    - **Validates: Requirements 5.5, 5.6**

  - [ ]* 2.4 Write property test for best discount wins per line item (Property 8)
    - **Property 8: Best discount wins per line item**
    - Generate a cart item + multiple matching discounts → assert `computeLineTotal` ≤ any individual discount's line total
    - **Validates: Requirements 5.2**

  - [ ]* 2.5 Write property test for discount scope matching (Property 13)
    - **Property 13: Discount scope matching**
    - Generate product-scoped and category-scoped discounts → assert `bestDiscount` returns match iff `item.id` or `item.categoryId` equals `targetId`
    - **Validates: Requirements 5.9, 5.10**

  - [ ]* 2.6 Write property test for savings invariant (Property 12)
    - **Property 12: Savings invariant**
    - Generate random carts + discounts → assert `totalSavings == sum(original - discounted)` and `grandTotal == subtotal - totalSavings`
    - **Validates: Requirements 5.7, 8.4**

- [x] 3. Implement `DiscountService` and `FirestoreDiscountService` in `lib/services/discount_service.dart`
  - Define `DiscountService` abstract class with: `watchActiveDiscounts()`, `watchAllDiscounts()`, `createDiscount(Discount)`, `updateDiscount(Discount)`, `setActive(String discountId, bool isActive)`
  - Implement `FirestoreDiscountService` querying `firestore.collection('discounts')`
  - `watchActiveDiscounts` filters on `isActive == true`; `watchAllDiscounts` returns all documents
  - `createDiscount` sets `isActive: true` and `createdAt: FieldValue.serverTimestamp()`
  - `updateDiscount` writes mutable fields only; `setActive` writes only the `isActive` field
  - _Requirements: 1.5, 1.6, 2.5, 3.3, 4.2, 4.3_

  - [ ]* 3.1 Write property test for active discount filter correctness (Property 2)
    - **Property 2: Active discount filter correctness**
    - Generate random `Discount` lists with mixed `isActive` → assert `watchActiveDiscounts` emits only `isActive == true` entries
    - **Validates: Requirements 1.5, 1.6**

  - [ ]* 3.2 Write property test for Firestore error produces non-null error message (Property 4)
    - **Property 4: Firestore error produces non-null error message**
    - Mock Firestore to throw on any write → assert UI state error message is non-null and non-empty
    - **Validates: Requirements 2.8, 3.5, 4.5**

  - [ ]* 3.3 Write property test for toggle isActive round-trip (Property 7)
    - **Property 7: Toggle isActive round-trip**
    - Generate random `Discount` → `setActive(false)` → `setActive(true)` → assert `isActive == true`
    - **Validates: Requirements 4.2, 4.3**

- [x] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Create Riverpod providers in `lib/providers/discount_providers.dart`
  - `discountServiceProvider` as `Provider<DiscountService>` returning `FirestoreDiscountService`
  - `activeDiscountsProvider` as `StreamProvider<List<Discount>>` backed by `discountServiceProvider.watchActiveDiscounts()`
  - `allDiscountsProvider` as `StreamProvider<List<Discount>>` backed by `discountServiceProvider.watchAllDiscounts()`
  - _Requirements: 1.5, 1.6, 5.1_

- [x] 6. Extend `CartState` and `CartNotifier` to consume `activeDiscountsProvider`
  - Add `discountedCart` field (`DiscountedCart?`) to `CartState` in `lib/models/cart_state.dart`; add `grandTotal` and `totalSavings` convenience getters that fall back to raw totals when `discountedCart` is null
  - Refactor `CartNotifier` in `lib/providers/cart_provider.dart` to extend `StateNotifier` and watch `activeDiscountsProvider` via `ref`; on every cart or discount change, call `DiscountEngine().compute(items, activeDiscounts)` and store the result in `CartState.discountedCart`
  - Keep all existing public methods (`addItem`, `incrementItem`, `decrementItem`, `clearCart`, `quantityOf`) unchanged
  - When `activeDiscountsProvider` is in error state, fall back to zero discounts (no crash)
  - _Requirements: 5.1, 5.2, 5.7_

- [x] 7. Create `DiscountBadge` shared widget in `lib/widgets/discount_badge.dart`
  - Implement `DiscountBadge extends StatelessWidget` accepting a `Discount discount` parameter
  - Render badge text: percentage → `"${value.toInt()}% OFF"`, bogo → `"BUY $buyQty GET $freeQty FREE"`, bulk → `"SAVE ${discountPercent.toInt()}% on $minQty+"`
  - Style consistently with the existing green badge style used in `cart_screen.dart` (`_kGreenLight` background, `_kGreen` text)
  - _Requirements: 6.2, 6.3, 6.4, 6.5_

  - [ ]* 7.1 Write property test for discount badge text format (Property 14)
    - **Property 14: Discount badge text format**
    - Generate random `Discount` objects of each type → render `DiscountBadge` → assert text matches expected format string
    - **Validates: Requirements 6.3, 6.4, 6.5**

- [x] 8. Implement `DiscountManagerScreen` in `lib/screens/admin/discount_manager_screen.dart`
  - Watch `allDiscountsProvider`; render a `ListView` of discount tiles each showing: name, type badge, scope + target name, and an `isActive` `Switch`
  - FAB opens a Create Discount bottom sheet with fields: name, type dropdown, scope dropdown, target selector (populated from `adminCategoriesProvider` / `adminProductsProvider` based on scope), and type-specific parameter fields shown/hidden per Requirements 2.2–2.4
  - Tapping a tile opens an Edit Discount bottom sheet pre-populated with current values (Requirement 3.2)
  - Form validates all fields before calling `DiscountService.createDiscount` / `updateDiscount`; shows field-level errors on invalid submit without writing to Firestore (Requirements 2.6, 3.4)
  - Toggle calls `DiscountService.setActive`; on Firestore error reverts toggle and shows snackbar (Requirement 4.5)
  - On stream error show error banner with retry that invalidates `allDiscountsProvider`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 8.1 Write property test for invalid form does not write to Firestore (Property 3)
    - **Property 3: Invalid form does not write to Firestore**
    - Generate forms with ≥1 invalid field → assert `createDiscount`/`updateDiscount` not called
    - **Validates: Requirements 2.6, 3.4**

  - [ ]* 8.2 Write property test for discount list tile renders all required fields (Property 5)
    - **Property 5: Discount list tile renders all required fields**
    - Generate random `Discount` objects → render tile → assert name, type label, scope label, and toggle value are present
    - **Validates: Requirements 3.1, 4.1**

  - [ ]* 8.3 Write property test for edit form pre-populates with current discount values (Property 6)
    - **Property 6: Edit form pre-populates with current discount values**
    - Generate random `Discount` → open edit form → assert all form field initial values match discount fields
    - **Validates: Requirements 3.2**

  - [ ]* 8.4 Write unit tests for `DiscountManagerScreen`
    - Test "Create Discount" FAB renders (Req 2.1)
    - Test selecting `type == "percentage"` shows value field, hides buyQty/freeQty/minQty (Req 2.2)
    - Test selecting `type == "bogo"` shows buyQty and freeQty fields (Req 2.3)
    - Test selecting `type == "bulk"` shows minQty and discountPercent fields (Req 2.4)
    - Test new discount created with `isActive == true` (Req 2.5)
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 9. Update router: add `/admin/discounts` route in `lib/router.dart`
  - Import `DiscountManagerScreen` and add a `GoRoute` for `/admin/discounts` inside the existing admin routes block
  - The existing `AdminRouterNotifier` redirect guard already covers all `/admin/*` paths, so no additional guard logic is needed
  - _Requirements: 9.2, 9.3_

  - [ ]* 9.1 Write property test for `/admin/discounts` route guard (Property 15)
    - **Property 15: /admin/discounts route guard**
    - Generate unauthenticated / non-admin states → assert `AdminRouterNotifier.redirect` returns `/admin/login` for `/admin/discounts`
    - **Validates: Requirements 9.3**

- [x] 10. Update `AdminDashboardScreen`: add Discount Manager navigation tile
  - Add a `_NavTile` entry with `icon: Icons.local_offer` and `title: 'Discount Manager'` that calls `context.push('/admin/discounts')` in `lib/screens/admin/admin_dashboard_screen.dart`
  - Place the tile after the existing Order Manager tile, before the Seed Data button
  - _Requirements: 9.1, 9.2_

  - [x] 10.1 Write unit tests for `AdminDashboardScreen` discount tile
    - Test "Discount Manager" navigation tile renders (Req 9.1)
    - Test tapping tile navigates to `/admin/discounts` (Req 9.2)
    - _Requirements: 9.1, 9.2_

- [x] 11. Update `HomeScreen`: add discount badge overlay on product cards
  - Watch `activeDiscountsProvider` in `HomeScreen` (or pass discounts down to product card widgets)
  - In the product card widget(s) (`_ProductGrid` / `_PrevCard`), call `DiscountEngine().bestDiscount(item, activeDiscounts)` and render a `DiscountBadge` overlay when a discount is found; render nothing when no discount applies (Requirement 6.6)
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 12. Update `ItemDetailScreen`: add discount badge and discounted price display
  - Watch `activeDiscountsProvider` in `ItemDetailScreen`; call `DiscountEngine().bestDiscount(item, activeDiscounts)` to get the applicable discount
  - When a `percentage` discount applies: show `DiscountBadge` and display discounted unit price alongside original price with strikethrough (Requirement 7.2)
  - When a `bogo` or `bulk` discount applies: show `DiscountBadge` and original unit price only (Requirement 7.3)
  - When no discount applies: show only the regular price without a badge (Requirement 7.4)
  - Replace the existing `item.offer`-based price/badge logic with the new `DiscountEngine`-based logic
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 13. Update `CartScreen`: add per-item discount badges and bill summary
  - In `_CartItemCard`, read `CartState.discountedCart` to get the `DiscountedLine` for each item; render `DiscountBadge` when `appliedDiscount != null` (Requirement 8.1)
  - For percentage discounts show discounted unit price + strikethrough original price (Requirement 8.2); for bogo/bulk show badge + discounted line total (Requirement 8.3)
  - When no discount applies show regular price and line total without badge (Requirement 8.5)
  - Update `_BillSummary` to read `CartState.discountedCart`: show subtotal (undiscounted), discount savings as a negative value, and grand total (Requirement 8.4)
  - Replace the existing `item.offer`-based helpers (`getOfferText`, `getDiscountedPrice`, `calculateItemTotal`) with `DiscountedCart` data from state
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 14. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Property tests use `glados` (add `glados: ^0.6.0` to `dev_dependencies` in `pubspec.yaml`)
- `DiscountEngine` is a pure class with no Firestore dependency — test it without mocking
- The existing `Item.offer` field is left in place for backward compatibility; `DiscountEngine` supersedes it for all cart calculations
- All discount code is additive — no existing customer files are deleted
