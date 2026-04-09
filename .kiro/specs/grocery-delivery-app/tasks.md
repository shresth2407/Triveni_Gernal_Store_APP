# Implementation Plan: Grocery Delivery App

## Overview

Implement a Flutter Android grocery delivery app using Firebase Auth, Firestore, Riverpod, go_router, geolocator, and upi_india. Tasks are ordered to build foundational layers first (dependencies, models, services) before wiring UI screens on top.

## Tasks

- [x] 1. Project setup — dependencies, Firebase, and folder structure
  - Add dependencies to `pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `geolocator`, `geocoding`, `upi_india`
  - Add dev dependencies: `build_runner`, `riverpod_generator`, `flutter_test`
  - Create folder structure: `lib/models/`, `lib/services/`, `lib/providers/`, `lib/screens/`, `lib/widgets/`
  - Initialize Firebase in `lib/main.dart` with `Firebase.initializeApp()` and wrap app in `ProviderScope`
  - _Requirements: 1.1, 7.1_

- [x] 2. Data models
  - [x] 2.1 Implement `Category`, `Item`, `CartItem`, `CartState`, `LocationState`, and `OrderRequest` Dart model classes in `lib/models/`
    - Add `fromFirestore` factory constructors for `Category` and `Item`
    - Add computed getters: `CartItem.lineTotal`, `CartState.total`, `CartState.isEmpty`
    - _Requirements: 3.1, 3.4, 5.1, 5.2, 6.7_

  - [ ]* 2.2 Write unit tests for model computed properties
    - Test `CartItem.lineTotal`, `CartState.total`, `CartState.isEmpty`
    - _Requirements: 5.1, 5.2_

- [x] 3. Services
  - [x] 3.1 Implement `FirebaseAuthService` (implements `AuthService`) in `lib/services/auth_service.dart`
    - Wire `signUp`, `signIn`, `signOut`, `currentUser`, `authStateChanges` to `firebase_auth`
    - _Requirements: 1.2, 1.3, 7.1, 7.4_

  - [x] 3.2 Implement `GeoLocationService` (implements `LocationService`) in `lib/services/location_service.dart`
    - Use `geolocator` for permission request and coordinate fetch; `geocoding` for address resolution
    - _Requirements: 2.2, 2.4, 2.5_

  - [x] 3.3 Implement `FirestoreProductService` (implements `ProductService`) in `lib/services/product_service.dart`
    - Implement `getCategories()`, `getItems({String? categoryId})`, `getItemById(String id)` against Firestore
    - _Requirements: 3.1, 3.2, 3.3_

  - [x] 3.4 Implement `FirestoreOrderService` (implements `OrderService`) in `lib/services/order_service.dart`
    - Implement `placeOrder(OrderRequest)` — writes to `orders` collection with all required fields and server timestamp
    - _Requirements: 6.4, 6.6, 6.7_

  - [x] 3.5 Implement `UpiPaymentService` (implements `PaymentService`) in `lib/services/payment_service.dart`
    - Wrap `upi_india` package; return `UpiResponse` from `initiateUpiPayment`
    - _Requirements: 6.3, 6.4, 6.5_

- [x] 4. Riverpod providers and state notifiers
  - [x] 4.1 Create service providers in `lib/providers/service_providers.dart`
    - `authServiceProvider`, `productServiceProvider`, `orderServiceProvider`, `paymentServiceProvider`
    - _Requirements: 1.2, 3.2, 6.4_

  - [x] 4.2 Create `authStateProvider` as `StreamProvider<User?>` in `lib/providers/auth_provider.dart`
    - _Requirements: 7.1, 7.2_

  - [x] 4.3 Implement `LocationNotifier` and `locationProvider` in `lib/providers/location_provider.dart`
    - State: `LocationState`; expose `detectGps()` and `setManual(String address)` and `clear()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 7.4_

  - [x] 4.4 Implement `CartNotifier` and `cartProvider` in `lib/providers/cart_provider.dart`
    - Implement `addItem`, `incrementItem`, `decrementItem` (removes at 0), `clearCart`, `quantityOf`
    - _Requirements: 4.3, 4.4, 4.5, 5.3, 5.4, 5.5, 7.3_

  - [ ]* 4.5 Write unit tests for `CartNotifier`
    - Test add, increment, decrement-to-zero (removal), clearCart, quantityOf
    - _Requirements: 4.3, 4.4, 4.5, 5.3, 5.4, 5.5_

  - [x] 4.6 Create `categoriesProvider` and `itemsProvider` in `lib/providers/product_providers.dart`
    - `categoriesProvider` as `FutureProvider<List<Category>>`
    - `itemsProvider(String? categoryId)` as family `FutureProvider<List<Item>>`
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 5. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Navigation with go_router
  - Implement `lib/router.dart` with all routes: `/auth`, `/location`, `/home`, `/item/:id`, `/cart`, `/checkout`, `/confirmation`
  - Add auth redirect guard: no Firebase user → `/auth`
  - Add location redirect guard: no saved location → `/location`
  - Wire router into `MaterialApp.router` in `main.dart`
  - _Requirements: 1.3, 2.1, 7.1, 7.2_

- [x] 7. Auth screen
  - [x] 7.1 Implement `AuthScreen` in `lib/screens/auth_screen.dart`
    - Single screen with togglable login / signup forms
    - Email and password fields with inline validation (invalid email format, password < 6 chars)
    - Loading indicator and disabled submit button while request is in progress
    - Display Firebase error messages inline
    - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 7.2 Write widget tests for `AuthScreen` validation
    - Test inline error for invalid email, short password, and Firebase error display
    - _Requirements: 1.4, 1.5, 1.6_

- [x] 8. Location screen
  - [x] 8.1 Implement `LocationScreen` in `lib/screens/location_screen.dart`
    - GPS detect button (calls `LocationNotifier.detectGps()`) with loading state
    - Manual address text field
    - Confirm button — validates non-empty, stores location, navigates to `/home`
    - Validation error when confirming empty field
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [ ]* 8.2 Write widget tests for `LocationScreen`
    - Test empty-field validation error and confirm navigation
    - _Requirements: 2.6, 2.7_

- [x] 9. Home screen
  - [x] 9.1 Implement `HomeScreen` in `lib/screens/home_screen.dart`
    - Horizontal scrollable category list; tapping a category filters items
    - Item grid/list with card showing image, name, price
    - Display saved delivery location
    - Loading indicator while fetching; error message with retry on Firestore failure
    - Logout button that calls `AuthService.signOut()`, clears cart and location, navigates to `/auth`
    - _Requirements: 2.8, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 7.4_

  - [ ]* 9.2 Write widget tests for `HomeScreen` category filtering
    - Test that selecting a category updates the displayed item list
    - _Requirements: 3.3_

- [x] 10. Item detail screen
  - [x] 10.1 Implement `ItemDetailScreen` in `lib/screens/item_detail_screen.dart`
    - Display image, name, category, description, price
    - Show current cart quantity (default 0); "Add to Cart" button when qty is 0
    - Increment / decrement controls when qty > 0; decrement to 0 removes item and reverts to "Add to Cart"
    - Navigate to cart button
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [x] 11. Cart screen
  - [x] 11.1 Implement `CartScreen` in `lib/screens/cart_screen.dart`
    - List of cart items: name, unit price, quantity, line total
    - Overall cart total
    - Increment / decrement controls per item (decrement to 0 removes row)
    - Empty state message + back-to-home button when cart is empty
    - "Proceed to Checkout" button enabled only when cart is non-empty
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [ ]* 11.2 Write widget tests for `CartScreen`
    - Test empty state display and total calculation updates on increment/decrement
    - _Requirements: 5.2, 5.6_

- [x] 12. Checkout screen and order placement
  - [x] 12.1 Implement `CheckoutScreen` in `lib/screens/checkout_screen.dart`
    - Order summary: items, quantities, line totals, delivery location, cart total
    - UPI and COD payment method selection
    - "Place Order" button: loading indicator + disabled while submitting
    - On UPI: invoke `PaymentService.initiateUpiPayment`; on success call `OrderService.placeOrder` and navigate to `/confirmation`; on failure show error
    - On COD: call `OrderService.placeOrder` directly and navigate to `/confirmation`
    - Firestore error handling with retry
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9_

  - [x] 12.2 Implement `OrderConfirmationScreen` in `lib/screens/order_confirmation_screen.dart`
    - Display order ID and confirmation message
    - Clear cart after successful order
    - Navigate back to home
    - _Requirements: 6.4, 6.6_

- [x] 13. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
