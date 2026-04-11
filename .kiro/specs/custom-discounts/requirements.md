# Requirements Document

## Introduction

The Custom Discounts feature adds a first-class promotions system to the Flutter grocery delivery app. Admins can create, edit, and deactivate discount rules of three types: percentage-off, Buy-N-Get-M-Free (BOGO), and quantity-threshold percentage discounts. Discount rules target specific products or entire categories. Active discounts are surfaced to customers on the home screen, item detail screen, and cart. The cart engine applies all active rules when computing line totals and the order grand total.

The feature extends the existing `offer` map embedded in the `Item` model into a standalone, Firestore-backed `Discount` entity managed independently of products, enabling discounts to be created, updated, and deactivated without editing individual product documents.

## Glossary

- **Discount**: A promotion rule stored in the Firestore `discounts` collection that defines a discount type, target scope, and active status.
- **Discount_Manager**: The admin screen under `/admin/discounts` for creating, editing, and deactivating Discounts.
- **Discount_Service**: The service responsible for reading and writing Discount documents to Firestore.
- **Discount_Engine**: The pure computation component that, given a list of active Discounts and a cart, calculates discounted line totals and total savings.
- **Percentage_Discount**: A Discount type that reduces the unit price of a targeted product or category by a fixed percentage (e.g. 10% off).
- **BOGO_Discount**: A Discount type where buying N units of a targeted product or category results in M additional units being free (e.g. Buy 2 Get 1 Free).
- **Bulk_Discount**: A Discount type that applies a percentage reduction to a targeted product or category when the cart quantity for that target meets or exceeds a minimum threshold (e.g. 10% off when quantity ≥ 10).
- **Discount_Scope**: The targeting dimension of a Discount — either `product` (applies to a single product by ID) or `category` (applies to all products in a category by category ID).
- **Active_Discount**: A Discount whose `isActive` field is `true`.
- **Discount_Badge**: A small UI label shown on product cards and the item detail screen indicating the best applicable Active_Discount for that product.
- **Cart_Engine**: The existing `CartNotifier` component, extended to apply Active_Discounts when computing line totals.
- **Admin**: A user whose UID exists in the Firestore `admins` collection.
- **Customer**: An authenticated non-admin user of the grocery delivery app.

---

## Requirements

### Requirement 1: Discount Data Model and Storage

**User Story:** As a developer, I want a well-defined Discount data model stored in Firestore, so that all parts of the app read from a single source of truth for promotion rules.

#### Acceptance Criteria

1. THE Discount_Service SHALL store each Discount as a document in the Firestore `discounts` collection with the following fields: `id` (String), `name` (String), `type` (String — one of `"percentage"`, `"bogo"`, `"bulk"`), `scope` (String — one of `"product"`, `"category"`), `targetId` (String — the product ID or category ID), `isActive` (bool), `createdAt` (Timestamp), and type-specific parameters as defined in criteria 2–4.
2. WHEN a Discount has `type == "percentage"`, THE Discount_Service SHALL store a `value` field (double, 0 < value ≤ 100) representing the percentage reduction.
3. WHEN a Discount has `type == "bogo"`, THE Discount_Service SHALL store `buyQty` (int ≥ 1) and `freeQty` (int ≥ 1) fields.
4. WHEN a Discount has `type == "bulk"`, THE Discount_Service SHALL store `minQty` (int ≥ 2) and `discountPercent` (double, 0 < discountPercent ≤ 100) fields.
5. THE Discount_Service SHALL expose a method to fetch all Active_Discounts as a real-time stream from Firestore, filtering on `isActive == true`.
6. THE Discount_Service SHALL expose a method to fetch all Discounts (active and inactive) for admin management purposes.

---

### Requirement 2: Admin — Create Discount

**User Story:** As an admin, I want to create new discount rules with a name, type, scope, and type-specific parameters, so that I can run promotions on specific products or categories.

#### Acceptance Criteria

1. THE Discount_Manager SHALL provide a "Create Discount" action that opens a form with fields: name, type (dropdown: Percentage / BOGO / Bulk), scope (dropdown: Product / Category), target selector (dropdown populated from existing products or categories based on scope), and type-specific parameter fields.
2. WHEN the admin selects `type == "percentage"`, THE Discount_Manager SHALL display a "Discount %" numeric field.
3. WHEN the admin selects `type == "bogo"`, THE Discount_Manager SHALL display "Buy Qty" and "Free Qty" numeric fields.
4. WHEN the admin selects `type == "bulk"`, THE Discount_Manager SHALL display "Min Qty" and "Discount %" numeric fields.
5. WHEN the admin submits the Create Discount form with all required fields valid, THE Discount_Service SHALL write a new Discount document to Firestore with `isActive` set to `true` and `createdAt` set to the server timestamp.
6. IF the admin submits the Create Discount form with any required field empty or with an out-of-range numeric value, THEN THE Discount_Manager SHALL display a field-level validation error and SHALL NOT write to Firestore.
7. WHEN the Discount_Service successfully writes the new Discount, THE Discount_Manager SHALL refresh the discount list and display the new entry.
8. IF Firestore returns an error during the write, THEN THE Discount_Manager SHALL display a descriptive error message with a retry option.

---

### Requirement 3: Admin — Edit Discount

**User Story:** As an admin, I want to edit an existing discount's name, parameters, and active status, so that I can adjust promotions without deleting and recreating them.

#### Acceptance Criteria

1. THE Discount_Manager SHALL display each Discount in the list with its name, type, scope, target name, and active status.
2. WHEN an admin taps a Discount in the list, THE Discount_Manager SHALL open an edit form pre-populated with the Discount's current field values.
3. WHEN the admin submits the edit form with all fields valid, THE Discount_Service SHALL update the corresponding Firestore `discounts` document and THE Discount_Manager SHALL refresh the list.
4. IF the admin submits the edit form with any required field empty or with an out-of-range numeric value, THEN THE Discount_Manager SHALL display a field-level validation error and SHALL NOT write to Firestore.
5. IF Firestore returns an error during the update, THEN THE Discount_Manager SHALL display a descriptive error message with a retry option.

---

### Requirement 4: Admin — Deactivate and Reactivate Discount

**User Story:** As an admin, I want to deactivate a discount without deleting it, so that I can pause promotions and reactivate them later.

#### Acceptance Criteria

1. THE Discount_Manager SHALL display a toggle or switch for each Discount that reflects its current `isActive` state.
2. WHEN an admin toggles a Discount's active switch to inactive, THE Discount_Service SHALL update the Discount's `isActive` field to `false` in Firestore.
3. WHEN an admin toggles a Discount's active switch to active, THE Discount_Service SHALL update the Discount's `isActive` field to `true` in Firestore.
4. WHEN the `isActive` field is updated, THE Discount_Manager SHALL reflect the new state immediately in the list without requiring a full page reload.
5. IF Firestore returns an error during the toggle update, THEN THE Discount_Manager SHALL display a descriptive error message and revert the toggle to its previous state.

---

### Requirement 5: Discount Engine — Cart Calculation

**User Story:** As a customer, I want my cart to automatically apply all active discounts to the correct products, so that I always pay the correct discounted price.

#### Acceptance Criteria

1. THE Cart_Engine SHALL fetch Active_Discounts from the Discount_Service on initialization and whenever the active discount list changes.
2. WHEN computing the line total for a cart item, THE Discount_Engine SHALL apply the best single Active_Discount that matches the item's product ID or category ID, selecting the discount that produces the lowest line total for that item.
3. WHEN a Percentage_Discount applies to a cart item with quantity Q and unit price P and discount value V, THE Discount_Engine SHALL compute the line total as `P × (1 − V/100) × Q`.
4. WHEN a BOGO_Discount with `buyQty` B and `freeQty` F applies to a cart item with quantity Q, THE Discount_Engine SHALL compute the number of payable units as `(Q ÷ (B + F)) × B + (Q mod (B + F))` and the line total as `payableUnits × P`.
5. WHEN a Bulk_Discount with `minQty` M and `discountPercent` D applies to a cart item with quantity Q where `Q ≥ M`, THE Discount_Engine SHALL compute the line total as `P × (1 − D/100) × Q`.
6. WHEN a Bulk_Discount applies to a cart item with quantity Q where `Q < M`, THE Discount_Engine SHALL compute the line total as `P × Q` (no discount applied).
7. THE Cart_Engine SHALL compute total savings as the sum over all cart items of `(item.price × quantity) − discounted line total`.
8. WHEN no Active_Discount matches a cart item, THE Discount_Engine SHALL compute the line total as `item.price × quantity`.
9. WHEN a Discount has `scope == "category"`, THE Discount_Engine SHALL apply it to all cart items whose `item.categoryId` equals the Discount's `targetId`.
10. WHEN a Discount has `scope == "product"`, THE Discount_Engine SHALL apply it only to the cart item whose `item.id` equals the Discount's `targetId`.

---

### Requirement 6: Customer — Discount Display on Home Screen

**User Story:** As a customer, I want to see discount badges on product cards on the home screen, so that I can quickly identify products with active promotions.

#### Acceptance Criteria

1. WHEN the Home_Screen loads, THE Home_Screen SHALL fetch and subscribe to the Active_Discounts stream from the Discount_Service.
2. WHEN an Active_Discount matches a product displayed on the Home_Screen, THE Home_Screen SHALL render a Discount_Badge on that product's card showing the offer text.
3. WHEN a Percentage_Discount applies, THE Discount_Badge SHALL display text in the format `"X% OFF"` where X is the discount value.
4. WHEN a BOGO_Discount applies, THE Discount_Badge SHALL display text in the format `"BUY B GET F FREE"` where B is `buyQty` and F is `freeQty`.
5. WHEN a Bulk_Discount applies, THE Discount_Badge SHALL display text in the format `"SAVE D% on M+"` where D is `discountPercent` and M is `minQty`.
6. WHEN no Active_Discount matches a product, THE Home_Screen SHALL render that product's card without a Discount_Badge.

---

### Requirement 7: Customer — Discount Display on Item Detail Screen

**User Story:** As a customer, I want to see the active discount and discounted price on the item detail screen, so that I understand the promotion before adding the item to my cart.

#### Acceptance Criteria

1. WHEN the Item_Detail_Screen loads for a product that has an applicable Active_Discount, THE Item_Detail_Screen SHALL display the Discount_Badge with the offer text.
2. WHEN a Percentage_Discount applies to the displayed product, THE Item_Detail_Screen SHALL display the discounted unit price alongside the original price with a strikethrough.
3. WHEN a BOGO_Discount or Bulk_Discount applies to the displayed product, THE Item_Detail_Screen SHALL display the Discount_Badge and the original unit price (since the effective price depends on cart quantity).
4. WHEN no Active_Discount applies to the displayed product, THE Item_Detail_Screen SHALL display only the regular price without a Discount_Badge.

---

### Requirement 8: Customer — Discount Display in Cart

**User Story:** As a customer, I want to see the applied discount and savings for each item in my cart, so that I can verify the correct promotions are being applied.

#### Acceptance Criteria

1. WHEN the Cart_Screen renders a cart item that has an applicable Active_Discount, THE Cart_Screen SHALL display the Discount_Badge for that item.
2. WHEN a Percentage_Discount applies to a cart item, THE Cart_Screen SHALL display the discounted unit price and the original price with a strikethrough.
3. WHEN a BOGO_Discount or Bulk_Discount applies to a cart item, THE Cart_Screen SHALL display the Discount_Badge and the computed discounted line total.
4. THE Cart_Screen SHALL display a bill summary showing: item subtotal (sum of undiscounted line totals), total discount savings (as a negative value), and grand total (subtotal minus savings).
5. WHEN no Active_Discount applies to a cart item, THE Cart_Screen SHALL display the regular unit price and line total without a Discount_Badge.

---

### Requirement 9: Admin Panel Navigation — Discount Manager Entry

**User Story:** As an admin, I want a Discount Manager entry on the admin dashboard, so that I can navigate to discount management from the main admin menu.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display a navigation entry for "Discount Manager" alongside the existing Category Manager, Product Manager, and Order Manager entries.
2. WHEN an admin taps the "Discount Manager" navigation entry, THE Admin_Router SHALL navigate to `/admin/discounts`.
3. THE Admin_Router SHALL guard the `/admin/discounts` route with the existing admin authentication check, redirecting unauthenticated or non-admin users to `/admin/login`.

---

### Requirement 10: Discount Consistency — Round-Trip Serialization

**User Story:** As a developer, I want Discount objects to serialize to and deserialize from Firestore without data loss, so that discount rules are stored and retrieved accurately.

#### Acceptance Criteria

1. THE Discount_Service SHALL implement a `Discount.fromFirestore` factory that reads all fields defined in Requirement 1 from a Firestore document snapshot.
2. THE Discount_Service SHALL implement a `Discount.toFirestore` method that writes all non-null fields of a Discount to a map suitable for Firestore.
3. FOR ALL valid Discount objects, serializing via `toFirestore` and then deserializing via `fromFirestore` SHALL produce a Discount object with identical field values (round-trip property).
