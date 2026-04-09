import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_order.dart';
import '../../providers/admin/admin_service_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderFuture = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(_orderDetailProvider(orderId)),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

final _orderDetailProvider =
    FutureProvider.family<AdminOrder, String>((ref, orderId) {
  return ref.watch(adminOrderServiceProvider).getOrderById(orderId);
});

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = order.createdAt;
    final formattedDate =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          Text('Order #${order.id}', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          _InfoRow(label: 'Status', value: order.status),
          _InfoRow(label: 'Payment', value: order.paymentMethod),
          _InfoRow(label: 'Created', value: formattedDate),
          _InfoRow(label: 'Delivery Location', value: order.deliveryLocation),
          const Divider(height: 32),

          // Items
          Text('Items', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...order.items.map((item) => _OrderItemRow(item: item)),
          const Divider(height: 32),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: textTheme.titleMedium),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final AdminOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text('\$${item.lineTotal.toStringAsFixed(2)}'),
        ],
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
