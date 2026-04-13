
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/admin/admin_data_providers.dart';

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

class OrderManagerScreen extends ConsumerWidget {
  const OrderManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            // ─── CUSTOM APP BAR ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
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
                          const Text('Order Manager', style: TextStyle(color: _kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Track and manage incoming orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── BODY CONTENT ───────────────────────────────────────
            SliverToBoxAdapter(
              child: ordersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: _kRed)),
                ),
                error: (error, _) => _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(adminOrdersProvider),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const _EmptyOrdersCard();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('${orders.length} Active Orders', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextGrey)),
                        ),
                        const SizedBox(height: 16),
                        // List
                        ...orders.map((order) => _OrderCard(order: order)).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ORDER CARD ─────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final dynamic order; // Using dynamic to be safe, but usually AdminOrder

  const _OrderCard({required this.order});

  // Helper to get status styling
  Map<String, dynamic> _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return {'color': const Color(0xFF2196F3), 'bg': const Color(0xFFE3F2FD), 'label': 'Confirmed'};
      case 'preparing':
        return {'color': const Color(0xFFFF9800), 'bg': const Color(0xFFFFF3E0), 'label': 'Preparing'};
      case 'out_for_delivery':
        return {'color': const Color(0xFFF57C00), 'bg': const Color(0xFFFFF3E0), 'label': 'Out for Delivery'};
      case 'delivered':
        return {'color': _kGreen, 'bg': _kGreenLight, 'label': 'Delivered'};
      case 'cancelled':
        return {'color': _kRed, 'bg': _kLightRed, 'label': 'Cancelled'};
      default:
        return {'color': _kTextGrey, 'bg': Colors.grey[200], 'label': status};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely access properties (assumed based on previous context)
    final orderId = order.id?.toString() ?? 'N/A';
    final total = order.totalAmount ?? 0.0;
    final status = order.status?.toString() ?? 'Unknown';
    final paymentMethod = order.paymentMethod?.toString() ?? 'Unknown';
    final createdAt = order.createdAt is DateTime ? order.createdAt as DateTime : DateTime.now();

    final statusData = _getStatusData(status);
    final statusColor = statusData['color'] as Color;
    final statusBg = statusData['bg'] as Color;
    final statusLabel = statusData['label'] as String;

    final fmt = DateFormat('MMM dd, hh:mm a');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/admin/orders/$orderId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kRoseBorder.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: ID & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kLightRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: _kRed, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kTextDark),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Row: Date & Payment
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: _kTextGrey),
                  const SizedBox(width: 4),
                  Text(fmt.format(createdAt), style: const TextStyle(fontSize: 12, color: _kTextGrey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.payments_rounded, size: 14, color: _kTextGrey),
                  const SizedBox(width: 4),
                  Text(paymentMethod, style: const TextStyle(fontSize: 12, color: _kTextGrey)),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: _kRoseBorder, height: 1),
              const SizedBox(height: 12),

              // Bottom Row: Total & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 12, color: _kTextGrey)),
                  Row(
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kRed),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _kBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: _kTextMid, size: 12),
                      ),
                    ],
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

// ─── EMPTY STATE CARD ───────────────────────────────────────────
class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kRoseBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRoseBorder, width: 2),
                ),
                child: const Icon(Icons.inbox_rounded, size: 40, color: _kRoseBorder),
              ),
              const SizedBox(height: 20),
              const Text('No Orders Found', style: TextStyle(color: _kTextDark, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('New orders will appear here.', textAlign: TextAlign.center, style: TextStyle(color: _kTextGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ERROR CARD ─────────────────────────────────────────────────
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
              Text('Oops!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kDarkRed)),
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: _kRed, fontWeight: FontWeight.w500, fontSize: 13)),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
