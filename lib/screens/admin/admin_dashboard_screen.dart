import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/admin_order.dart';
import '../../providers/admin/admin_service_providers.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/admin/admin_auth_provider.dart';
import '../../services/admin/fcm_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSeeding = false;
  final AdminFcmService _fcmService = AdminFcmService();

  @override
  void initState() {
    super.initState();
    // Initialize FCM
    _initializeFcm();
    // Listen for new order notifications
    _setupOrderNotifications();
  }

  Future<void> _initializeFcm() async {
    final adminUser = ref.read(adminAuthStateProvider).valueOrNull;
    if (adminUser != null) {
      await _fcmService.initialize(adminUser.uid);
    }
  }

  void _setupOrderNotifications() {
    // Listen to new order stream
    ref.listenManual(newOrderNotificationsProvider, (previous, next) {
      next.whenData((order) {
        if (!mounted) return;
        
        // Show notification snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'New Order Received!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Order #${order.id.substring(0, 8)} • ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.push('/admin/orders/${order.id}'),
            ),
          ),
        );
      });
    });
  }

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
    final adminUser = ref.read(adminAuthStateProvider).valueOrNull;
    if (adminUser != null) {
      await _fcmService.removeToken(adminUser.uid);
    }
    await ref.read(adminAuthServiceProvider).signOut();
    if (!mounted) return;
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    final latestOrdersAsync = ref.watch(latestOrdersProvider(10));
    final pendingOrdersAsync = ref.watch(adminOrdersProvider);
    final pendingCount = pendingOrdersAsync.valueOrNull?.length ?? 0;
    
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
          // Quick Actions Section
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.category,
            title: 'Category Manager',
            onTap: () => context.push('/admin/categories'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.inventory_2,
            title: 'Product Manager',
            onTap: () => context.push('/admin/products'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.receipt_long,
            title: 'Order Manager',
            badge: pendingCount > 0 ? pendingCount : null,
            onTap: () => context.push('/admin/orders'),
          ),
          const SizedBox(height: 12),
          _NavTile(
            icon: Icons.local_offer,
            title: 'Discount Manager',
            onTap: () => context.push('/admin/discounts'),
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
          
          const SizedBox(height: 32),
          
          // Latest Orders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/admin/orders'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          latestOrdersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Failed to load orders: $error'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(latestOrdersProvider(10)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No orders yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return Column(
                children: orders.map((order) => _OrderQuickCard(order: order)).toList(),
              );
            },
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
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (badge != null) const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ORDER QUICK CARD (for dashboard)
// ═════════════════════════════════════════════════════════════════
class _OrderQuickCard extends StatelessWidget {
  final AdminOrder order;

  const _OrderQuickCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'out_for_delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(order.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    order.paymentMethod == 'COD' 
                        ? Icons.money_outlined 
                        : Icons.qr_code_scanner_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
