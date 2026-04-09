# Requirements Document

## Introduction

An Admin Panel feature added to the existing Flutter Android grocery delivery app. Admins access a separate, role-gated section of the same codebase to manage categories, products, and orders. Role-based routing ensures admin and customer flows are fully separated. Admin identity is determined by a Firestore `admins` collection lookup after Firebase Auth login. The panel supports category management, product management (create/edit with price, quantity, and offer price), order viewing, and a seed-data utility for testing.

## Glossary

- **Admin**: A user whose UID exists in the Firestore `admins` collection and who has access to the Admin Panel.
- **Admin_Panel**: The set of admin-only screens within the app, accessible only to authenticated Admins.
- **Admin_Auth_Screen**: The login screen used by Admins to authenticate. Reuses Firebase Auth but adds a role check.
- **Admin_Dashboard**: The root screen of the Admin Panel, providing navigation to all admin sections.
- **Category_Manager**: The admin screen for viewing, adding, and editing product categories.
- **Product_Manager**: The admin screen for viewing, adding, and editing grocery products.
- **Order_Manager**: The admin screen for viewing pending orders and their details.
- **Role_Checker**: The service responsible for verifying whether an authenticated user is an Admin by querying Firestore.
- **Admin_Router**: The go_router routing logic that enforces admin-only access and separates admin routes from customer routes.
- **Seed_Service**: A utility service that writes a predefined set of dummy categories and products to Firestore for testing purposes.
- **Category**: A grouping label for grocery products stored in the Firestore `categories` collection.
- **Product**: A grocery item stored in the Firestore `products` collection with name, description, imageUrl, price, offerPrice, quantity, categoryId, and inStock fields.
- **Order**: A purchase record in the Firestore `orders` collection with status, items, totalAmount, userId, deliveryLocation, paymentMethod, and createdAt fields.
- **Offer_Price**: An optional discounted price for a Product, displayed to customers instead of the regular price when set.

---

## Requirements

### Requirement 1: Admin Authentication and Role Verification

**User Story:** As an admin, I want to log in with my email and password and have the app verify my admin role, so that only authorized admins can access the Admin Panel.

#### Acceptance Criteria

1. THE Admin_Auth_Screen SHALL display an email and password login form separate from the customer Auth_Screen.
2. WHEN an admin submits valid credentials, THE Admin_Auth_Screen SHALL authenticate the user via Firebase_Auth and then invoke the Role_Checker.
3. WHEN the Role_Checker confirms the authenticated user's UID exists in the Firestore `admins` collection, THE Admin_Router SHALL navigate to the Admin_Dashboard.
4. IF the Role_Checker determines the authenticated user's UID does not exist in the Firestore `admins` collection, THEN THE Admin_Auth_Screen SHALL sign the user out via Firebase_Auth and display the message "Access denied: not an admin account."
5. IF Firebase_Auth returns an authentication error, THEN THE Admin_Auth_Screen SHALL display a descriptive error message and SHALL NOT invoke the Role_Checker.
6. WHILE an authentication or role-check request is in progress, THE Admin_Auth_Screen SHALL display a loading indicator and disable the submit button.
7. THE Admin_Router SHALL redirect any unauthenticated request to an admin route back to the Admin_Auth_Screen.
8. THE Admin_Router SHALL redirect any authenticated non-admin request to an admin route back to the Admin_Auth_Screen.

---

### Requirement 2: Admin Dashboard Navigation

**User Story:** As an admin, I want a central dashboard with clear navigation to all admin sections, so that I can efficiently move between managing categories, products, and orders.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display navigation entries for: Category Manager, Product Manager, and Order Manager.
2. WHEN an admin taps a navigation entry, THE Admin_Router SHALL navigate to the corresponding admin screen.
3. THE Admin_Dashboard SHALL display a logout button that signs the admin out via Firebase_Auth and navigates to the Admin_Auth_Screen.
4. WHILE the admin is authenticated, THE Admin_Dashboard SHALL remain accessible without re-authentication.

---

### Requirement 3: Category Management

**User Story:** As an admin, I want to view, add, and edit product categories, so that I can keep the category list accurate and up to date.

#### Acceptance Criteria

1. THE Category_Manager SHALL display a list of all Categories fetched from the Firestore `categories` collection, showing each category's name and sort order.
2. WHEN the Category_Manager loads, THE Category_Manager SHALL fetch the current list of Categories from Firestore ordered by sortOrder.
3. THE Category_Manager SHALL provide an "Add Category" action that opens a form to enter a category name, imageUrl, and sortOrder.
4. WHEN an admin submits the Add Category form with all required fields filled, THE Category_Manager SHALL write the new Category document to the Firestore `categories` collection and refresh the displayed list.
5. IF an admin submits the Add Category form with any required field empty, THEN THE Category_Manager SHALL display a validation error for each empty field and SHALL NOT write to Firestore.
6. THE Category_Manager SHALL allow an admin to select an existing Category to open an edit form pre-populated with the category's current values.
7. WHEN an admin submits the edit form with valid data, THE Category_Manager SHALL update the corresponding Firestore `categories` document and refresh the displayed list.
8. IF Firestore returns an error during a read or write operation, THEN THE Category_Manager SHALL display a descriptive error message with a retry option.

---

### Requirement 4: Product Management

**User Story:** As an admin, I want to add new products and edit existing ones with price, quantity, offer price, and category, so that the product catalog stays current.

#### Acceptance Criteria

1. THE Product_Manager SHALL display a list of all Products fetched from the Firestore `products` collection, showing each product's name, price, and category name.
2. WHEN the Product_Manager loads, THE Product_Manager SHALL fetch all Products and all Categories from Firestore to populate the product list and category selector.
3. THE Product_Manager SHALL provide an "Add Product" action that opens a form with fields: name, description, imageUrl, categoryId (dropdown of existing Categories), price, offerPrice (optional), quantity, and inStock toggle.
4. WHEN an admin submits the Add Product form with all required fields filled and valid, THE Product_Manager SHALL write the new Product document to the Firestore `products` collection and refresh the displayed list.
5. IF an admin submits the Add Product form with any required field empty or with a non-numeric value in a numeric field, THEN THE Product_Manager SHALL display a field-level validation error and SHALL NOT write to Firestore.
6. THE Product_Manager SHALL allow an admin to select an existing Product to open an edit form pre-populated with the product's current values.
7. WHEN an admin submits the edit form with valid data, THE Product_Manager SHALL update the corresponding Firestore `products` document and refresh the displayed list.
8. WHEN an admin sets an offerPrice on a Product, THE Product_Manager SHALL store the offerPrice field on the Firestore `products` document alongside the regular price.
9. IF Firestore returns an error during a read or write operation, THEN THE Product_Manager SHALL display a descriptive error message with a retry option.

---

### Requirement 5: Order Management

**User Story:** As an admin, I want to view pending orders and their details, so that I can monitor and fulfill customer orders.

#### Acceptance Criteria

1. THE Order_Manager SHALL display a list of Orders from the Firestore `orders` collection where status is "confirmed", ordered by createdAt descending.
2. WHEN the Order_Manager loads, THE Order_Manager SHALL fetch and display all pending Orders from Firestore in real time using a Firestore stream.
3. THE Order_Manager SHALL display for each Order: the order ID, customer user ID, total amount, payment method, and creation timestamp.
4. WHEN an admin taps an Order in the list, THE Order_Manager SHALL display a detail view showing the full order: delivery location, all ordered items with quantities and line totals, total amount, payment method, and status.
5. IF the Firestore stream returns an error, THEN THE Order_Manager SHALL display a descriptive error message with a retry option.
6. WHILE no pending Orders exist, THE Order_Manager SHALL display an empty state message indicating no pending orders.

---

### Requirement 6: Seed Data Utility

**User Story:** As an admin, I want a button to populate Firestore with dummy categories and products, so that I can test the app without manually entering data.

#### Acceptance Criteria

1. THE Admin_Dashboard SHALL display a "Seed Data" button visible only when the admin is authenticated.
2. WHEN an admin taps the "Seed Data" button, THE Seed_Service SHALL write a predefined set of at least 3 Categories and at least 6 Products to Firestore, using batch writes.
3. WHEN the Seed_Service completes successfully, THE Admin_Dashboard SHALL display a confirmation message indicating how many categories and products were seeded.
4. IF the Seed_Service encounters a Firestore error during the batch write, THEN THE Admin_Dashboard SHALL display a descriptive error message.
5. WHILE the Seed_Service is writing to Firestore, THE Admin_Dashboard SHALL display a loading indicator on the "Seed Data" button and disable it to prevent duplicate writes.

---

### Requirement 7: Admin Routing and Customer Flow Isolation

**User Story:** As the app, I want admin and customer routes to be fully separated, so that admins and customers never accidentally access each other's screens.

#### Acceptance Criteria

1. THE Admin_Router SHALL define all admin routes under the `/admin` path prefix (e.g., `/admin/login`, `/admin/dashboard`, `/admin/categories`, `/admin/products`, `/admin/orders`).
2. THE App SHALL maintain the existing customer routes unchanged under their current paths.
3. WHEN a customer-authenticated user navigates to any `/admin` route, THE Admin_Router SHALL redirect to `/admin/login`.
4. WHEN an admin-authenticated user navigates to any customer route, THE App SHALL allow access without interference, as admin accounts are also valid Firebase Auth users.
5. THE Admin_Router SHALL integrate with the existing go_router configuration without replacing or modifying the customer routing guards.
