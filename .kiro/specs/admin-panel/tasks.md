# Implementation Plan: Admin Panel

## Overview

Add a role-gated admin panel to the existing Flutter grocery delivery app. Tasks are ordered foundationally: models first, then services, providers, routing, and finally UI screens. All admin code is purely additive — no existing customer files are removed or broken.

## Tasks

- [x] 1. Update `Item` model with admin fields
  - Add `offerPrice` (nullable `double`) and `quantity` (`int`, default 0) fields to `Item` in `lib/models/item.dart`
  - Add `effectivePrice` getter: returns `offerPrice ?? price`
  - Extend `Item.fromFirestore` to read `offerPrice` and `quantity` as optional fields (backward compatible)
  - Add `toFirestore()` method returning a `Map<String, dynamic>` with all fields; omit `offerPrice` key when null
  - _Requirements: 4.8_

  - [ ]* 1.1 Write property test for `effectivePrice` (Property 19)
    - **Property 19: effectivePrice returns offerPrice when set, otherwise regular price**
    - **Validates: Requirements 4.8**

  - [ ]* 1.2 Write property test for `toFirestore` offerPrice field (Property 14)
    - **Property 14: offerPrice is stored alongside regular price**
    - **Validates: Requirements 4.8**

- [x] 2. Add new admin models in `lib/models/`
  - Create `lib/models/admin_order.dart` with `AdminOrderItem` (productId, name, unitPrice, quantity, lineTotal) and `AdminOrder` (id, userId, deliveryLocation, items, totalAmount, paymentMethod, status, createdAt) with `AdminOrder.fromFirestore` factory
  - Create `lib/models/admin_state.dart` with `AdminAuthStatus` enum (unknown, unauthenticated, authenticating, authenticated, notAdmin) and `AdminState` class (status, errorMessage, user)
  - Create `lib/models/seed_result.dart` with `SeedResult` (categoriesSeeded, productsSeeded)
  - Export all three from `lib/models/models.dart`
  - _Requirements: 5.3, 5.4, 1.6, 6.3_

- [x] 3. Implement admin services in `lib/services/admin/`
  - [x] 3.1 Implement `AdminAuthService` abstract class and `FirebaseAdminAuthService` in `lib/services/admin/admin_auth_service.dart`
    - Abstract: `signIn(email, password)`, `isAdmin(uid)`, `signOut()`, `currentUser`, `authStateChanges`
    - `FirebaseAdminAuthService`: delegates sign-in/out to `FirebaseAuth`; `isAdmin` checks existence of `admins/{uid}` document in Firestore
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 3.2 Write property test for auth error prevents role check (Property 3)
    - **Property 3: Auth error prevents Role_Checker invocation**
    - **Validates: Requirements 1.5**

  - [ ]* 3.3 Write property test for role check navigation outcome (Property 2)
    - **Property 2: Role check determines navigation outcome**
    - **Validates: Requirements 1.2, 1.3, 1.4**

  - [x] 3.4 Implement `AdminProductService` abstract class and `FirestoreAdminProductService` in `lib/services/admin/admin_product_service.dart`
    - Abstract: `getCategories()`, `getProducts()`, `addCategory(Category)`, `updateCategory(Category)`, `addProduct(Item)`, `updateProduct(Item)`
    - `FirestoreAdminProductService`: `getCategories` orders by `sortOrder`; write methods use `collection.doc(id).set/update` with `item.toFirestore()`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.7, 4.1, 4.2, 4.4, 4.7_

  - [ ]* 3.5 Write property test for category sort order (Property 4)
    - **Property 4: Category list is ordered by sortOrder**
    - **Validates: Requirements 3.1, 3.2**

  - [ ]* 3.6 Write property test for category add round-trip (Property 5)
    - **Property 5: Valid category add appears in list**
    - **Validates: Requirements 3.4**

  - [ ]* 3.7 Write property test for category edit round-trip (Property 8)
    - **Property 8: Valid category edit updates Firestore document**
    - **Validates: Requirements 3.7**

  - [ ]* 3.8 Write property test for product add round-trip (Property 11)
    - **Property 11: Valid product add appears in list**
    - **Validates: Requirements 4.4**

  - [ ]* 3.9 Write property test for product edit round-trip (Property 13)
    - **Property 13: Valid product edit updates Firestore document**
    - **Validates: Requirements 4.7**

  - [x] 3.10 Implement `AdminOrderService` abstract class and `FirestoreAdminOrderService` in `lib/services/admin/admin_order_service.dart`
    - Abstract: `watchPendingOrders()` → `Stream<List<AdminOrder>>`, `getOrderById(String)` → `Future<AdminOrder>`
    - `FirestoreAdminOrderService`: `watchPendingOrders` queries `orders` where `status == "confirmed"` ordered by `createdAt` descending as a snapshot stream
    - _Requirements: 5.1, 5.2, 5.4_

  - [ ]* 3.11 Write property test for order list filter and sort (Property 15)
    - **Property 15: Order list contains only confirmed orders in descending createdAt order**
    - **Validates: Requirements 5.1, 5.2**

  - [x] 3.12 Implement `SeedService` abstract class and `FirestoreSeedService` in `lib/services/admin/seed_service.dart`
    - Abstract: `seedData()` → `Future<SeedResult>`
    - `FirestoreSeedService`: uses a single `WriteBatch` to atomically write ≥3 categories and ≥6 products; returns `SeedResult` with counts
    - _Requirements: 6.2, 6.3_

  - [ ]* 3.13 Write property test for seed minimum counts (Property 17)
    - **Property 17: Seed result meets minimum count requirements**
    - **Validates: Requirements 6.2, 6.3**

- [x] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement admin Riverpod providers in `lib/providers/admin/`
  - [x] 5.1 Create service providers in `lib/providers/admin/admin_service_providers.dart`
    - `adminAuthServiceProvider` as `Provider<AdminAuthService>`
    - `adminProductServiceProvider` as `Provider<AdminProductService>`
    - `adminOrderServiceProvider` as `Provider<AdminOrderService>`
    - `seedServiceProvider` as `Provider<SeedService>`
    - _Requirements: 1.2, 3.4, 5.2, 6.2_

  - [x] 5.2 Create auth state and role providers in `lib/providers/admin/admin_auth_provider.dart`
    - `adminAuthStateProvider` as `StreamProvider<User?>` backed by `adminAuthServiceProvider.authStateChanges`
    - `adminRoleProvider` as `FutureProvider<bool>` that calls `adminAuthService.isAdmin(uid)` when user is non-null, returns false otherwise
    - _Requirements: 1.2, 1.3, 1.7, 1.8_

  - [x] 5.3 Create data providers in `lib/providers/admin/admin_data_providers.dart`
    - `adminCategoriesProvider` as `FutureProvider<List<Category>>` backed by `adminProductServiceProvider.getCategories()`
    - `adminProductsProvider` as `FutureProvider<List<Item>>` backed by `adminProductServiceProvider.getProducts()`
    - `adminOrdersProvider` as `StreamProvider<List<AdminOrder>>` backed by `adminOrderServiceProvider.watchPendingOrders()`
    - _Requirements: 3.1, 4.1, 5.2_

  - [ ]* 5.4 Write property test for Firestore error triggers error state (Property 9)
    - **Property 9: Firestore error triggers error display**
    - **Validates: Requirements 3.8, 4.9, 5.5**

- [x] 6. Implement `AdminRouterNotifier` and wire admin routes into `lib/router.dart`
  - Create `AdminRouterNotifier extends ChangeNotifier` in `lib/router.dart` (or a separate `lib/admin_router.dart`)
    - Listens to `adminAuthStateProvider` and `adminRoleProvider`; notifies on change
    - `redirect` method: allows `/admin/login` through unconditionally; redirects any other `/admin/*` path to `/admin/login` if unauthenticated or not admin
  - Add `adminRouterNotifierProvider` as a `Provider<AdminRouterNotifier>`
  - Append admin `GoRoute` entries to the existing routes list in `routerProvider` (under `/admin/login`, `/admin/dashboard`, `/admin/categories`, `/admin/products`, `/admin/orders`, `/admin/orders/:id`)
  - Add `AdminRouterNotifier` as an additional `refreshListenable` alongside the existing `RouterNotifier`
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 1.7, 1.8_

  - [ ]* 6.1 Write property test for admin redirect (Property 1)
    - **Property 1: Admin redirect for unauthenticated and non-admin users**
    - **Validates: Requirements 1.7, 1.8, 7.3**

  - [ ]* 6.2 Write property test for admin user on customer routes (Property 18)
    - **Property 18: Admin user can access customer routes without redirect**
    - **Validates: Requirements 7.4**

- [x] 7. Implement `AdminLoginScreen` in `lib/screens/admin/admin_login_screen.dart`
  - Email and password text fields with inline validation
  - Submit button calls `AdminAuthService.signIn`; on success calls `isAdmin`; navigates to `/admin/dashboard` if admin, shows "Access denied: not an admin account." and signs out if not
  - Loading indicator and disabled submit button while request is in progress
  - Display Firebase error messages inline without invoking role check
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

  - [ ]* 7.1 Write unit tests for `AdminLoginScreen`
    - Test email and password fields render, loading state disables button, Firebase error displays inline, access-denied message shown for non-admin
    - _Requirements: 1.1, 1.5, 1.6_

- [x] 8. Implement `AdminDashboardScreen` in `lib/screens/admin/admin_dashboard_screen.dart`
  - Navigation tiles for Category Manager, Product Manager, and Order Manager
  - Logout button that calls `AdminAuthService.signOut` and navigates to `/admin/login`
  - "Seed Data" button visible when authenticated; shows loading indicator and is disabled while seeding
  - On seed success display confirmation snackbar with counts from `SeedResult`; on error display error snackbar
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.1, 6.3, 6.4, 6.5_

  - [ ]* 8.1 Write unit tests for `AdminDashboardScreen`
    - Test three navigation tiles render, logout button present, Seed Data button present and disabled during write
    - _Requirements: 2.1, 2.3, 6.1, 6.5_

- [x] 9. Implement `CategoryManagerScreen` in `lib/screens/admin/category_manager_screen.dart`
  - List all categories from `adminCategoriesProvider` showing name and sortOrder
  - "Add Category" FAB opens a form (name, imageUrl, sortOrder); validates all fields non-empty before calling `AdminProductService.addCategory`; shows field-level errors on empty submit
  - Tapping a category opens the same form pre-populated with current values for editing; calls `AdminProductService.updateCategory` on submit
  - Invalidates `adminCategoriesProvider` after successful write to refresh the list
  - Displays error banner with retry on Firestore failure
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

  - [ ]* 9.1 Write property test for invalid category form does not write (Property 6)
    - **Property 6: Invalid category form does not write to Firestore**
    - **Validates: Requirements 3.5**

  - [ ]* 9.2 Write property test for edit form pre-population (Property 7)
    - **Property 7: Edit form pre-populates with current entity values**
    - **Validates: Requirements 3.6, 4.6**

- [x] 10. Implement `ProductManagerScreen` in `lib/screens/admin/product_manager_screen.dart`
  - List all products from `adminProductsProvider` showing name, price, and category name (resolved from `adminCategoriesProvider`)
  - "Add Product" FAB opens a form with fields: name, description, imageUrl, category dropdown, price, offerPrice (optional), quantity, inStock toggle
  - Validates required fields and numeric fields before calling `AdminProductService.addProduct`; shows field-level errors on invalid submit
  - Tapping a product opens the same form pre-populated for editing; calls `AdminProductService.updateProduct` on submit
  - Invalidates `adminProductsProvider` after successful write to refresh the list
  - Displays error banner with retry on Firestore failure
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_

  - [ ]* 10.1 Write property test for invalid product form does not write (Property 12)
    - **Property 12: Invalid product form does not write to Firestore**
    - **Validates: Requirements 4.5**

  - [ ]* 10.2 Write property test for product row displays required fields (Property 10)
    - **Property 10: Product list displays required fields for every product**
    - **Validates: Requirements 4.1**

- [x] 11. Implement `OrderManagerScreen` and `OrderDetailScreen` in `lib/screens/admin/`
  - `OrderManagerScreen` (`order_manager_screen.dart`): real-time list from `adminOrdersProvider`; each row shows order ID, userId, totalAmount, paymentMethod, createdAt; empty state message when list is empty; error banner with retry on stream error; tapping a row navigates to `/admin/orders/:id`
  - `OrderDetailScreen` (`order_detail_screen.dart`): receives order ID via path parameter; calls `AdminOrderService.getOrderById`; displays deliveryLocation, all items with quantities and line totals, totalAmount, paymentMethod, status
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 11.1 Write property test for order row displays required fields (Property 16)
    - **Property 16: Order row displays all required fields**
    - **Validates: Requirements 5.3**

  - [ ]* 11.2 Write unit tests for `OrderManagerScreen`
    - Test empty state message shown when order list is empty, loading state, error banner on stream error
    - _Requirements: 5.5, 5.6_

- [x] 12. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests use `glados` (add `glados: ^0.6.0` to dev_dependencies in `pubspec.yaml`)
- All admin code is additive — no existing customer files are modified except `lib/models/item.dart` and `lib/router.dart`
