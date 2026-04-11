import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_order.dart';
import '../../providers/admin/admin_service_providers.dart';

// Available order statuses
const List<String> _orderStatuses = [
  'confirmed',
  'preparing',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

// Status display names
const Map<String, String> _statusDisplayNames = {
  'confirmed': 'Confirmed',
  'preparing': 'Preparing',
  'out_for_delivery': 'Out for Delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

// Status colors
const Map<String, Color> _statusColors = {
  'confirmed': Color(0xFF2196F3),
  'preparing': Color(0xFFFF9800),
  'out_for_delivery': Color(0xFFFF9800),
  'delivered': Color(0xFF4CAF50),
  'cancelled': Color(0xFFF44336),
};

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isUpdatingStatus = false;
  String? _statusError;

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
      _statusError = null;
    });

    try {
      await ref
          .read(adminOrderServiceProvider)
          .updateOrderStatus(widget.orderId, newStatus);
      
      if (!mounted) return;
      
      // Refresh the order data
      ref.invalidate(_orderDetailProvider(widget.orderId));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${_statusDisplayNames[newStatus]}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = 'Failed to update status: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderFuture = ref.watch(_orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(_orderDetailProvider(widget.orderId)),
        ),
        data: (order) => _OrderDetailBody(
          order: order,
          isUpdatingStatus: _isUpdatingStatus,
          statusError: _statusError,
          onStatusChange: _updateStatus,
        ),
      ),
    );
  }
}

final _orderDetailProvider =
    FutureProvider.family<AdminOrder, String>((ref, orderId) {
  return ref.watch(adminOrderServiceProvider).getOrderById(orderId);
});

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.isUpdatingStatus,
    required this.onStatusChange,
    this.statusError,
  });

  final AdminOrder order;
  final bool isUpdatingStatus;
  final String? statusError;
  final Function(String) onStatusChange;

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
          const SizedBox(height: 16),

          // Status Change Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Order Status',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Current Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColors[order.status]?.withOpacity(0.1) ?? Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColors[order.status] ?? Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Current: ${_statusDisplayNames[order.status] ?? order.status}',
                    style: TextStyle(
                      color: _statusColors[order.status] ?? Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status Change Buttons
                Text(
                  'Change Status:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _orderStatuses.map((status) {
                    final isCurrentStatus = status == order.status;
                    final statusColor = _statusColors[status] ?? Colors.grey;
                    
                    return ElevatedButton(
                      onPressed: isCurrentStatus || isUpdatingStatus
                          ? null
                          : () => onStatusChange(status),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentStatus
                            ? statusColor.withOpacity(0.3)
                            : statusColor,
                        foregroundColor: isCurrentStatus
                            ? statusColor
                            : Colors.white,
                        disabledBackgroundColor: statusColor.withOpacity(0.3),
                        disabledForegroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _statusDisplayNames[status] ?? status,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                if (isUpdatingStatus) ...[
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Updating status...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                
                if (statusError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Customer Information
          Text('Customer Information', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _InfoRow(label: 'Name', value: order.userName.isNotEmpty ? order.userName : 'Not provided'),
          _InfoRow(label: 'Phone', value: order.userPhone.isNotEmpty ? order.userPhone : 'Not provided'),
          const Divider(height: 24),

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
