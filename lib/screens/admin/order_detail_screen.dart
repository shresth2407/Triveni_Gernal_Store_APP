
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/admin_order.dart';
import '../../providers/admin/admin_service_providers.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed         = Color(0xFFDC143C);
const _kDarkRed     = Color(0xFFB22222);
const _kLightRed    = Color(0xFFFFF0F0);
const _kRoseBorder  = Color(0xFFFFCDD2);
const _kBg          = Color(0xFFF7F7F7);
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF1A1A1A);
const _kTextGrey    = Color(0xFF9E9E9E);
const _kTextMid     = Color(0xFF555555);
const _kGreen       = Color(0xFF2E7D32);
const _kGreenLight  = Color(0xFFE8F5E9);

// ─── STATUS CONFIG (Unchanged Logic) ─────────────────────────────
const List<String> _orderStatuses = [
  'confirmed',
  'preparing',
  'out_for_delivery',
  'delivered',
  'cancelled',
];

const Map<String, String> _statusDisplayNames = {
  'confirmed': 'Confirmed',
  'preparing': 'Preparing',
  'out_for_delivery': 'Out for Delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

const Map<String, Color> _statusColors = {
  'confirmed': Color(0xFF1976D2),      // Blue
  'preparing': Color(0xFFF57C00),      // Orange
  'out_for_delivery': Color(0xFFE65100), // Dark Orange
  'delivered': _kGreen,
  'cancelled': _kRed,
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

  // ─── LOGIC (Unchanged) ─────────────────────────────────────────
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: _kWhite, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Status updated to ${_statusDisplayNames[newStatus]}')),
            ],
          ),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            // ─── CUSTOM APP BAR ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: _kWhite,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRoseBorder, width: 1),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kRed, size: 16),
                ),
                onPressed: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_kDarkRed, _kRed], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Details', style: TextStyle(color: _kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Manage and track order progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── BODY ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: orderFuture.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: _kRed)),
                ),
                error: (error, _) => _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(_orderDetailProvider(widget.orderId)),
                ),
                data: (order) => Column(
                  children: [
                    // Order ID & Total Card
                    _OrderSummaryCard(order: order),
                    const SizedBox(height: 20),

                    // Status Management Card
                    _StatusManagementCard(
                      order: order,
                      isUpdating: _isUpdatingStatus,
                      error: _statusError,
                      onUpdate: _updateStatus,
                    ),
                    const SizedBox(height: 20),

                    // Customer Info Card
                    _InfoCard(order: order),
                    const SizedBox(height: 20),

                    // Items List Card
                    _ItemsCard(order: order),
                    const SizedBox(height: 55),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROVIDER (Unchanged) ─────────────────────────────────────────
final _orderDetailProvider =
FutureProvider.family<AdminOrder, String>((ref, orderId) {
  return ref.watch(adminOrderServiceProvider).getOrderById(orderId);
});

// ─── WIDGETS ─────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final AdminOrder order;
  const _OrderSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID', style: TextStyle(fontSize: 11, color: _kTextGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('#${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kTextDark)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total Amount', style: TextStyle(fontSize: 11, color: _kTextGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('₹ ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kRed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusManagementCard extends StatelessWidget {
  final AdminOrder order;
  final bool isUpdating;
  final String? error;
  final Function(String) onUpdate;

  const _StatusManagementCard({
    required this.order,
    required this.isUpdating,
    required this.error,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currentColor = _statusColors[order.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── LIGHT HEADER SECTION ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kLightRed, _kWhite], stops: const [0.5, 1.0]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: currentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sync_rounded, color: currentColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kTextDark)),
                    Text('Update tracking progress', style: TextStyle(fontSize: 11, color: _kTextGrey)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: currentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: currentColor),
                      const SizedBox(width: 6),
                      Text(_statusDisplayNames[order.status] ?? order.status,
                          style: TextStyle(color: currentColor, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Change Status Header
                const Text('Change Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextDark)),
                const SizedBox(height: 12),

                // Status Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _orderStatuses.map((status) {
                    final isCurrent = status == order.status;
                    final color = _statusColors[status] ?? Colors.grey;

                    return GestureDetector(
                      onTap: (isCurrent || isUpdating) ? null : () { HapticFeedback.lightImpact(); onUpdate(status); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? color.withOpacity(0.1) : _kWhite,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isCurrent ? color : _kRoseBorder,
                            width: isCurrent ? 1.5 : 1,
                          ),
                          boxShadow: isCurrent ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _statusDisplayNames[status]!,
                              style: TextStyle(
                                color: isCurrent ? color : _kTextMid,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check, size: 14, color: color),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (isUpdating) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kRed)),
                      SizedBox(width: 8),
                      Text('Updating status...', style: TextStyle(fontSize: 12, color: _kTextGrey)),
                    ],
                  ),
                ],

                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: _kRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(error!, style: const TextStyle(color: _kDarkRed, fontSize: 12))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AdminOrder order;
  const _InfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark)),
          const SizedBox(height: 16),
          _DetailTile(icon: Icons.person_outline_rounded, label: 'Name', value: order.userName),
          const SizedBox(height: 12),
          _DetailTile(icon: Icons.phone_outlined, label: 'Phone', value: order.userPhone),
          const SizedBox(height: 12),
          _DetailTile(icon: Icons.location_on_outlined, label: 'Location', value: order.deliveryLocation),
          const SizedBox(height: 12),
          _DetailTile(icon: Icons.payment_outlined, label: 'Payment', value: order.paymentMethod),
          const SizedBox(height: 12),
          _DetailTile(icon: Icons.calendar_today_outlined, label: 'Date', value: fmt.format(order.createdAt)),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final AdminOrder order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Order Items (${order.items.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark)),
          ),
          ...order.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _ItemTile(item: item, isLast: index == order.items.length - 1);
          }),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 14, color: _kTextGrey)),
                Text('₹ ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kRed)),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _kLightRed, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _kRed, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _kTextGrey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: _kTextDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AdminOrderItem item;
  final bool isLast;

  const _ItemTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _kRoseBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _kLightRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _kRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark)),
                const SizedBox(height: 4),
                Text('₹ ${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}', style: const TextStyle(fontSize: 12, color: _kTextGrey)),
              ],
            ),
          ),
          Text('₹ ${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kLightRed,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kRoseBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                child: const Icon(Icons.refresh, color: _kWhite, size: 24),
              ),
              const SizedBox(height: 16),
              const Text('Failed to load order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kDarkRed)),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _kRed, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: _kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
