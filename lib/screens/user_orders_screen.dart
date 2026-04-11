import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/admin_order.dart';
import '../providers/service_providers.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed         = Color(0xFFDC143C);
const _kRoseBorder  = Color(0xFFFFCDD2);
const _kBg          = Color(0xFFF7F7F7);
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF1A1A1A);
const _kTextGrey    = Color(0xFF9E9E9E);
const _kTextMid     = Color(0xFF555555);
const _kGreen       = Color(0xFF2E7D32);
const _kOrange      = Color(0xFFFF6D00);
const _kBlue        = Color(0xFF1976D2);

class UserOrdersScreen extends ConsumerWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        
        // ── APP BAR ──────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _kTextDark, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kTextDark,
            ),
          ),
        ),

        body: ordersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kRed),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: _kRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load orders',
                  style: const TextStyle(color: _kTextMid, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userOrdersProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: _kWhite,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 80, color: _kTextGrey),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start shopping to see your orders here',
                      style: TextStyle(color: _kTextGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: _kWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Shopping',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ORDER CARD
// ═════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final AdminOrder order;

  const _OrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return _kBlue;
      case 'preparing':
        return _kOrange;
      case 'out_for_delivery':
        return _kOrange;
      case 'delivered':
        return _kGreen;
      case 'cancelled':
        return _kRed;
      default:
        return _kTextGrey;
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant_outlined;
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRoseBorder, width: 1),
                  ),
                  child: Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kTextMid,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items summary
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: _kTextGrey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextMid,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _kRed,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Delivery location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: _kTextGrey, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryLocation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kTextMid,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Payment method
                Row(
                  children: [
                    Icon(
                      order.paymentMethod == 'COD' 
                          ? Icons.money_outlined 
                          : Icons.qr_code_scanner_rounded,
                      color: _kTextGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.paymentMethod == 'COD' ? 'Cash on Delivery' : 'UPI Payment',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Items list (collapsed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kTextMid,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: _kRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.name} x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kTextDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${item.lineTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kTextDark,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (order.items.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${order.items.length - 3} more items',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kTextGrey,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
