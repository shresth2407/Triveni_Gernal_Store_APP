import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin/admin_service_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSeeding = false;

  Future<void> _seedData() async {
    setState(() => _isSeeding = true);

    try {
      final result = await ref.read(seedServiceProvider).seedData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seeded ${result.categoriesSeeded} categories and ${result.productsSeeded} products',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seed failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(adminAuthServiceProvider).signOut();
    if (!mounted) return;
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavTile(
            icon: Icons.category,
            title: 'Category Manager',
            onTap: () => context.go('/admin/categories'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.inventory_2,
            title: 'Product Manager',
            onTap: () => context.go('/admin/products'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.receipt_long,
            title: 'Order Manager',
            onTap: () => context.go('/admin/orders'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSeeding ? null : _seedData,
            child: _isSeeding
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Seed Data'),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
