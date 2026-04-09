import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin/admin_data_providers.dart';

class OrderManagerScreen extends ConsumerWidget {
  const OrderManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Manager')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No pending orders.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final d = order.createdAt;
              final formattedDate =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
                  '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              return ListTile(
                title: Text('Order #${order.id}'),
                subtitle: Text(
                  'User: ${order.userId}\n'
                  '${order.paymentMethod} · $formattedDate',
                ),
                isThreeLine: true,
                trailing: Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => context.push('/admin/orders/${order.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
