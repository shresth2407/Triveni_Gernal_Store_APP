import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/service_providers.dart';
import 'providers/admin/admin_auth_provider.dart';
import 'models/location_state.dart';
import 'models/user_profile.dart';
import 'screens/auth_screen.dart';
import 'screens/location_screen.dart';
import 'screens/home_screen.dart';
import 'screens/all_products_screen.dart';
import 'screens/item_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/user_orders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/category_manager_screen.dart';
import 'screens/admin/product_manager_screen.dart';
import 'screens/admin/order_manager_screen.dart';
import 'screens/admin/order_detail_screen.dart';
import 'screens/admin/discount_manager_screen.dart';

/// A [ChangeNotifier] that listens to auth and location state changes
/// and notifies go_router to re-evaluate redirect guards.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to auth state changes
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, __) {
      notifyListeners();
    });
    // Listen to location state changes
    _ref.listen<LocationState>(locationProvider, (_, __) {
      notifyListeners();
    });
  }

  /// Redirect logic evaluated on every navigation event.
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;

    // Admin routes are handled entirely by AdminRouterNotifier — skip them here
    if (path.startsWith('/admin')) return null;

    // Allow splash screen to handle initial routing
    if (path == '/') return null;

    final authState = _ref.read(authStateProvider);
    final locationState = _ref.read(locationProvider);

    final isAuthenticated = authState.valueOrNull != null;
    final hasLocation = locationState.address != null;
    final isLoadingLocation = locationState.isLoading;

    final isOnAuth = path == '/auth';
    final isOnLocation = path == '/location';

    // Auth guard: no user → /auth
    if (!isAuthenticated) {
      return isOnAuth ? null : '/auth';
    }

    // Wait for location to finish loading before redirecting
    if (isLoadingLocation) {
      return null;
    }

    // Location guard: authenticated but no location → /location
    // Only redirect if user doesn't have location AND is not already on location page
    if (!hasLocation) {
      return isOnLocation ? null : '/location';
    }

    // Authenticated + has location: redirect away from /auth only
    // Allow access to /location for changing address
    if (isOnAuth) {
      return '/home';
    }

    return null;
  }
}

/// A [ChangeNotifier] that listens to admin auth and role state changes
/// and notifies go_router to re-evaluate admin redirect guards.
class AdminRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AdminRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(adminAuthStateProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen<AsyncValue<bool>>(adminRoleProvider, (_, __) {
      notifyListeners();
    });
  }

  /// Redirect logic for admin routes only.
  /// Returns null for non-admin paths (no interference with customer routes).
  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.matchedLocation;

    // Only handle /admin/* paths
    if (!path.startsWith('/admin')) return null;

    // Always allow /admin/login through
    if (path == '/admin/login') return null;

    final adminAuthState = _ref.read(adminAuthStateProvider);
    final isAuthenticated = adminAuthState.valueOrNull != null;

    if (!isAuthenticated) return '/admin/login';

    final isAdmin = _ref.read(adminRoleProvider).valueOrNull ?? false;
    if (!isAdmin) return '/admin/login';

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final adminRouterNotifierProvider = Provider<AdminRouterNotifier>((ref) {
  return AdminRouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  final adminNotifier = ref.watch(adminRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([notifier, adminNotifier]),
    redirect: (context, state) {
      final customerRedirect = notifier.redirect(context, state);
      if (customerRedirect != null) return customerRedirect;
      return adminNotifier.redirect(context, state);
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        // builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/all-products',
        builder: (context, state) => const AllProductsScreen(),
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) => ItemDetailScreen(
          itemId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const OrderConfirmationScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const UserOrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Admin routes
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const CategoryManagerScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ProductManagerScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const OrderManagerScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/discounts',
        builder: (context, state) => const DiscountManagerScreen(),
      ),
    ],
  );
});
