// Unit tests for AdminDashboardScreen — Discount Manager tile
// Validates: Requirements 9.1, 9.2

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:groicery_delivery/screens/admin/admin_dashboard_screen.dart';
import 'package:groicery_delivery/providers/admin/admin_service_providers.dart';
import 'package:groicery_delivery/services/admin/admin_auth_service.dart';
import 'package:groicery_delivery/services/admin/seed_service.dart';
import 'package:groicery_delivery/models/seed_result.dart';

// ---------------------------------------------------------------------------
// Minimal fakes — no Firebase calls
// ---------------------------------------------------------------------------

class _FakeAdminAuthService implements AdminAuthService {
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<bool> isAdmin(String uid) async => true;
  @override
  Future<void> signOut() async {}
  @override
  get currentUser => null;
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
}

class _FakeSeedService implements SeedService {
  @override
  Future<SeedResult> seedData() async => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Helper: build the screen inside a GoRouter + ProviderScope
// ---------------------------------------------------------------------------

Widget _buildScreen({required List<String> navigatedRoutes}) {
  final router = GoRouter(
    initialLocation: '/admin/dashboard',
    routes: [
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/discounts',
        builder: (_, __) => const Scaffold(body: Text('Discounts')),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (_, __) => const Scaffold(body: Text('Orders')),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (_, __) => const Scaffold(body: Text('Products')),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (_, __) => const Scaffold(body: Text('Categories')),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
    ],
    observers: [
      _RouteObserver(navigatedRoutes),
    ],
  );

  return ProviderScope(
    overrides: [
      adminAuthServiceProvider.overrideWithValue(_FakeAdminAuthService()),
      seedServiceProvider.overrideWithValue(_FakeSeedService()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _RouteObserver extends NavigatorObserver {
  _RouteObserver(this.routes);
  final List<String> routes;

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) routes.add(name);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AdminDashboardScreen — Discount Manager tile', () {
    testWidgets('renders "Discount Manager" navigation tile (Req 9.1)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(navigatedRoutes: []));
      await tester.pumpAndSettle();

      expect(find.text('Discount Manager'), findsOneWidget);
    });

    testWidgets('Discount Manager tile has local_offer icon (Req 9.1)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(navigatedRoutes: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });

    testWidgets(
        'tapping Discount Manager tile navigates to /admin/discounts (Req 9.2)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(navigatedRoutes: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discount Manager'));
      await tester.pumpAndSettle();

      // After navigation the Discounts stub screen should be visible
      expect(find.text('Discounts'), findsOneWidget);
    });

    testWidgets('Discount Manager tile appears after Order Manager tile',
        (tester) async {
      await tester.pumpWidget(_buildScreen(navigatedRoutes: []));
      await tester.pumpAndSettle();

      final orderPos =
          tester.getTopLeft(find.text('Order Manager')).dy;
      final discountPos =
          tester.getTopLeft(find.text('Discount Manager')).dy;

      expect(discountPos, greaterThan(orderPos));
    });
  });
}
