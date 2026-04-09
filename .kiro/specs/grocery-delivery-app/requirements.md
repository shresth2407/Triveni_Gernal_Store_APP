# Requirements Document

## Introduction

A Flutter grocery delivery application targeting Android devices. The app allows users to register and log in, browse grocery items by category, view item details, manage a shopping cart, and complete purchases via UPI payment or cash on delivery. Firebase serves as the backend for authentication, product data, and order management. Location capture is mandatory before browsing or placing orders.

## Glossary

- **App**: The Flutter Android grocery delivery application.
- **Auth_Screen**: The single screen handling both user login and signup with email and password.
- **Firebase_Auth**: Firebase Authentication service used for email/password login and registration.
- **Firestore**: Firebase Cloud Firestore database storing products, categories, and orders.
- **Home_Screen**: The main screen displaying grocery categories and items after authentication.
- **Category**: A grouping label for grocery items (e.g., Fruits, Vegetables, Dairy, Bakery).
- **Item**: A grocery product with a name, image, description, price, and category.
- **Item_Detail_Screen**: The screen showing full details of a selected grocery item.
- **Cart**: An in-memory and/or Firestore-backed collection of items the user intends to purchase.
- **Cart_Screen**: The screen displaying all items in the Cart with quantity controls.
- **Checkout_Screen**: The screen where the user reviews the order and selects a payment method.
- **UPI_Payment**: Payment via any installed UPI app on the device, initiated through a Flutter UPI library.
- **COD**: Cash on Delivery — a payment option where the user pays upon receiving the order.
- **Location**: The user's delivery address or GPS-derived location required before browsing or ordering.
- **Location_Screen**: The screen or dialog prompting the user to provide or confirm their delivery location.
- **Order**: A confirmed purchase record stored in Firestore containing items, quantities, total, payment method, and delivery location.

---

## Requirements

### Requirement 1: User Authentication

**User Story:** As a new or returning user, I want a single screen to register or log in with my email and password, so that I can access the app securely without navigating between separate screens.

#### Acceptance Criteria

1. THE Auth_Screen SHALL display both a login form and a signup form, togglable on the same screen.
2. WHEN a user submits the signup form with a valid email and password, THE Firebase_Auth SHALL create a new user account and sign the user in automatically.
3. WHEN a user submits the login form with a registered email and password, THE Firebase_Auth SHALL authenticate the user and navigate to the Location_Screen if no location is saved, or to the Home_Screen if a location is already saved.
4. IF a user submits the login or signup form with an invalid email format, THEN THE Auth_Screen SHALL display an inline validation error message below the email field.
5. IF a user submits the signup form with a password shorter than 6 characters, THEN THE Auth_Screen SHALL display an inline validation error message below the password field.
6. IF Firebase_Auth returns an authentication error (e.g., wrong password, email already in use), THEN THE Auth_Screen SHALL display a descriptive error message to the user.
7. WHILE an authentication request is in progress, THE Auth_Screen SHALL display a loading indicator and disable the submit button.

---

### Requirement 2: Mandatory Location Capture

**User Story:** As the app, I want to require every user to provide a delivery location before browsing, so that delivery availability and address are always known before an order is placed.

#### Acceptance Criteria

1. WHEN a user successfully authenticates and no delivery location is stored for the session, THE App SHALL navigate to the Location_Screen before displaying the Home_Screen.
2. THE Location_Screen SHALL provide an option to detect the user's current location using the device GPS.
3. THE Location_Screen SHALL provide an option for the user to manually enter a delivery address as free text.
4. WHEN the user grants location permission and requests GPS detection, THE Location_Screen SHALL populate the address field with the resolved address within 10 seconds.
5. IF the user denies location permission, THEN THE Location_Screen SHALL allow the user to enter the delivery address manually and SHALL NOT block progress after a manual address is entered.
6. WHEN the user confirms a non-empty delivery location, THE App SHALL store the location for the session and navigate to the Home_Screen.
7. IF the user attempts to confirm an empty location field, THEN THE Location_Screen SHALL display a validation error and SHALL NOT navigate away.
8. WHILE the app is running, THE App SHALL display the saved delivery location on the Home_Screen.

---

### Requirement 3: Home Screen — Category and Item Browsing

**User Story:** As a logged-in user, I want to browse grocery items organized by category on the home screen, so that I can quickly find what I need.

#### Acceptance Criteria

1. THE Home_Screen SHALL display a horizontally scrollable list of Categories fetched from Firestore.
2. WHEN the Home_Screen loads, THE App SHALL fetch and display all available Categories and their associated Items from Firestore.
3. WHEN a user selects a Category, THE Home_Screen SHALL filter the displayed Items to show only those belonging to the selected Category.
4. THE Home_Screen SHALL display each Item as a card showing the item image, name, and price.
5. WHEN a user taps an Item card, THE App SHALL navigate to the Item_Detail_Screen for that Item.
6. IF Firestore returns an error while loading categories or items, THEN THE Home_Screen SHALL display an error message with a retry option.
7. WHILE items are being fetched from Firestore, THE Home_Screen SHALL display a loading indicator in place of the item list.

---

### Requirement 4: Item Detail Screen

**User Story:** As a user, I want to view full details of a grocery item and add it to my cart, so that I can make informed purchase decisions.

#### Acceptance Criteria

1. THE Item_Detail_Screen SHALL display the Item's image, name, category, description, and price.
2. THE Item_Detail_Screen SHALL display the current quantity of the Item in the Cart (defaulting to 0).
3. WHEN a user taps the "Add to Cart" button, THE Cart SHALL add one unit of the Item and THE Item_Detail_Screen SHALL update the displayed quantity to reflect the new Cart total for that Item.
4. WHEN the displayed quantity is greater than 0, THE Item_Detail_Screen SHALL show increment and decrement controls alongside the quantity.
5. WHEN a user taps the decrement control and the Item quantity in the Cart is 1, THE Cart SHALL remove the Item entirely and THE Item_Detail_Screen SHALL revert to showing the "Add to Cart" button.
6. THE Item_Detail_Screen SHALL display a button to navigate to the Cart_Screen.

---

### Requirement 5: Shopping Cart

**User Story:** As a user, I want to review and adjust the items in my cart before checkout, so that I can confirm my order is correct.

#### Acceptance Criteria

1. THE Cart_Screen SHALL display a list of all Items currently in the Cart, each showing the item name, unit price, current quantity, and line total (unit price × quantity).
2. THE Cart_Screen SHALL display the overall Cart total (sum of all line totals).
3. WHEN a user taps the increment control for an Item in the Cart, THE Cart SHALL increase that Item's quantity by 1 and THE Cart_Screen SHALL update the line total and overall total immediately.
4. WHEN a user taps the decrement control for an Item in the Cart and the quantity is greater than 1, THE Cart SHALL decrease that Item's quantity by 1 and THE Cart_Screen SHALL update the totals immediately.
5. WHEN a user taps the decrement control for an Item in the Cart and the quantity is exactly 1, THE Cart SHALL remove the Item from the Cart and THE Cart_Screen SHALL remove the item row from the list.
6. IF the Cart is empty, THEN THE Cart_Screen SHALL display an empty state message and a button to navigate back to the Home_Screen.
7. THE Cart_Screen SHALL display a "Proceed to Checkout" button that is enabled only when the Cart contains at least one Item.

---

### Requirement 6: Checkout and Payment

**User Story:** As a user, I want to review my order and pay using UPI or cash on delivery, so that I can complete my grocery purchase conveniently.

#### Acceptance Criteria

1. THE Checkout_Screen SHALL display an order summary including all Cart items, quantities, line totals, delivery location, and the Cart total.
2. THE Checkout_Screen SHALL present two payment method options: UPI Payment and Cash on Delivery.
3. WHEN a user selects UPI Payment and taps "Place Order", THE App SHALL invoke the UPI payment library to present available UPI apps installed on the device.
4. WHEN the UPI payment library returns a successful transaction response, THE App SHALL create an Order record in Firestore with status "confirmed" and navigate to an order confirmation screen.
5. IF the UPI payment library returns a failure or cancellation response, THEN THE App SHALL display an error message on the Checkout_Screen and SHALL NOT create an Order record.
6. WHEN a user selects Cash on Delivery and taps "Place Order", THE App SHALL create an Order record in Firestore with payment method "COD" and status "confirmed", then navigate to an order confirmation screen.
7. THE Order record stored in Firestore SHALL contain the user ID, delivery location, list of items with quantities and prices, total amount, payment method, and a server timestamp.
8. WHILE an order is being submitted to Firestore, THE Checkout_Screen SHALL display a loading indicator and disable the "Place Order" button.
9. IF Firestore returns an error while saving the Order, THEN THE Checkout_Screen SHALL display an error message and allow the user to retry.

---

### Requirement 7: Session and Navigation

**User Story:** As a user, I want the app to remember my authentication state and cart across screen transitions, so that I don't lose my progress.

#### Acceptance Criteria

1. WHEN the App is launched and Firebase_Auth reports an existing authenticated session, THE App SHALL skip the Auth_Screen and navigate directly to the Location_Screen or Home_Screen as appropriate.
2. WHEN the App is launched and no authenticated session exists, THE App SHALL display the Auth_Screen.
3. THE Cart SHALL persist its state across all screen navigations within a single app session.
4. THE App SHALL provide a logout option accessible from the Home_Screen that signs the user out via Firebase_Auth and navigates back to the Auth_Screen, clearing the Cart and saved location.
