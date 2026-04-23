import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/admin_order.dart';
import '../../providers/admin/admin_service_providers.dart';
import '../../providers/admin/admin_data_providers.dart';
import '../../providers/admin/admin_auth_provider.dart';
import '../../services/admin/fcm_service.dart';

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
const _kGreenBright = Color(0xFF43A047);
const _kGreenLight  = Color(0xFFE8F5E9);

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
    _initializeFcm();
    _setupOrderNotifications();
  }

  Future<void> _initializeFcm() async {
    final adminUser = ref.read(adminAuthStateProvider).valueOrNull;
    if (adminUser != null) await _fcmService.initialize(adminUser.uid);
  }

  void _setupOrderNotifications() {
    ref.listenManual(newOrderNotificationsProvider, (previous, next) {
      next.whenData((order) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
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
                  child: const Icon(Icons.notifications_active, color: _kWhite, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('New Order Received! 🎉',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kWhite)),
                      Text(
                        'Order #${order.id.substring(0, 8)} • ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _kGreenBright,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            action: SnackBarAction(
              label: 'View →',
              textColor: _kWhite,
              onPressed: () => context.push('/admin/orders/${order.id}'),
            ),
          ),
        );
      });
    });
  }

  Future<void> _seedData() async {
    setState(() => _isSeeding = true);
    HapticFeedback.mediumImpact();
    try {
      final result = await ref.read(seedServiceProvider).seedData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ Seeded ${result.categoriesSeeded} categories & ${result.productsSeeded} products'),
        backgroundColor: _kGreenBright,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Seed failed: $e'),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _logout() async {
    final adminUser = ref.read(adminAuthStateProvider).valueOrNull;
    if (adminUser != null) await _fcmService.removeToken(adminUser.uid);
    await ref.read(adminAuthServiceProvider).signOut();
    if (!mounted) return;
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    final latestOrdersAsync = ref.watch(latestOrdersProvider(10));
    final pendingOrdersAsync = ref.watch(adminOrdersProvider);
    final pendingCount = pendingOrdersAsync.valueOrNull?.length ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.5),
            child: Container(height: 1.5, color: _kRoseBorder),
          ),
          title: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: _kWhite, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kTextDark)),
                  Text('Triveni General Store', style: TextStyle(fontSize: 10, color: _kTextGrey, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          actions: [
            if (pendingCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active, color: _kWhite, size: 12),
                        const SizedBox(width: 3),
                        Text('$pendingCount', style: const TextStyle(color: _kWhite, fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.only(right: 16, left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRoseBorder, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: _kRed, size: 14),
                    SizedBox(width: 4),
                    Text('Logout', style: TextStyle(fontSize: 12, color: _kRed, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _WelcomeCard(pendingCount: pendingCount),
              const SizedBox(height: 20),

              // Quick actions grid
              const _SectionLabel(title: 'Quick Actions'),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _NavCard(
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    subtitle: 'Add & manage',
                    gradient: [const Color(0xFFB22222), _kRed],
                    onTap: () => context.push('/admin/categories'),
                  ),
                  _NavCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Products',
                    subtitle: 'Stock & pricing',
                    gradient: [const Color(0xFF1565C0), const Color(0xFF1E88E5)],
                    onTap: () => context.push('/admin/products'),
                  ),
                  _NavCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    subtitle: 'Track & update',
                    gradient: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                    badge: pendingCount > 0 ? pendingCount : null,
                    onTap: () => context.push('/admin/orders'),
                  ),
                  _NavCard(
                    icon: Icons.local_offer_rounded,
                    title: 'Discounts',
                    subtitle: 'Offers & coupons',
                    gradient: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
                    onTap: () => context.push('/admin/discounts'),
                  ),
                ],
              ),

              // const SizedBox(height: 20),
              //
              // // Seed card
              // const _SectionLabel(title: 'Database'),
              // const SizedBox(height: 10),
              // _SeedCard(isSeeding: _isSeeding, onSeed: _seedData),

              // const SizedBox(height: 20),

              // Latest orders

              SizedBox(height: 8,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel(title: 'Latest Orders'),
                  GestureDetector(
                    onTap: () => context.push('/admin/orders'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kLightRed,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kRoseBorder, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('See All', style: TextStyle(fontSize: 12, color: _kRed, fontWeight: FontWeight.w700)),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, color: _kRed, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              latestOrdersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: _kRed),
                  ),
                ),
                error: (error, _) => _ErrorCard(
                  message: 'Failed to load orders',
                  onRetry: () => ref.invalidate(latestOrdersProvider(10)),
                ),
                data: (orders) {
                  if (orders.isEmpty) return const _EmptyOrdersCard();
                  return Column(
                    children: orders.map((o) => _OrderQuickCard(order: o)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WELCOME CARD ─────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final int pendingCount;
  const _WelcomeCard({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_kDarkRed, _kRed], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          Positioned(right: -16, top: -16,
              child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
          Positioned(right: 24, bottom: -18,
              child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👋 Welcome Back!', style: TextStyle(color: _kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('Manage your store from here.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MiniBadge(icon: Icons.bolt, label: '8 mins delivery'),
                  _MiniBadge(icon: Icons.storefront_outlined, label: 'Store Online'),
                  if (pendingCount > 0)
                    _MiniBadge(icon: Icons.pending_actions_rounded, label: '$pendingCount Pending', bgColor: Colors.white.withOpacity(0.3)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? bgColor;
  const _MiniBadge({required this.icon, required this.label, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor ?? Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kWhite, size: 12),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _kWhite, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kDarkRed, _kRed], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextDark)),
      ],
    );
  }
}

// ─── NAV CARD ─────────────────────────────────────────────────────
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int? badge;

  const _NavCard({required this.icon, required this.title, required this.subtitle, required this.gradient, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(right: -10, bottom: -10,
                child: Container(width: 55, height: 55, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: _kWhite, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _kWhite, fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: badge != null
                  ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text('$badge', style: TextStyle(color: gradient.first, fontSize: 11, fontWeight: FontWeight.w900)),
              )
                  : Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.5), size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SEED CARD ────────────────────────────────────────────────────
class _SeedCard extends StatelessWidget {
  final bool isSeeding;
  final VoidCallback onSeed;
  const _SeedCard({required this.isSeeding, required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kRoseBorder, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0EB22222), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _kLightRed, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kRoseBorder, width: 1.5)),
              child: const Icon(Icons.storage_rounded, color: _kRed, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seed Sample Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextDark)),
                  SizedBox(height: 2),
                  Text('Populate categories & products\nfor testing', style: TextStyle(fontSize: 11, color: _kTextGrey, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isSeeding ? null : onSeed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isSeeding ? [const Color(0xFFCC5555), const Color(0xFFCC5555)] : [_kDarkRed, _kRed]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSeeding ? [] : [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: isSeeding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _kWhite))
                    : const Text('Seed', style: TextStyle(color: _kWhite, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ORDER QUICK CARD ─────────────────────────────────────────────
class _OrderQuickCard extends StatelessWidget {
  final AdminOrder order;
  const _OrderQuickCard({required this.order});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':    return const Color(0xFF1565C0);
      case 'preparing':   return const Color(0xFFE65100);
      case 'out_for_delivery': return const Color(0xFFFF6D00);
      case 'delivered':   return _kGreenBright;
      case 'cancelled':   return _kRed;
      default:            return _kTextGrey;
    }
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':    return const Color(0xFFE3F2FD);
      case 'preparing':   return const Color(0xFFFFF3E0);
      case 'out_for_delivery': return const Color(0xFFFFF3E0);
      case 'delivered':   return _kGreenLight;
      case 'cancelled':   return _kLightRed;
      default:            return _kBg;
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':    return Icons.check_circle_outline_rounded;
      case 'preparing':   return Icons.restaurant_rounded;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'delivered':   return Icons.task_alt_rounded;
      case 'cancelled':   return Icons.cancel_outlined;
      default:            return Icons.hourglass_empty_rounded;
    }
  }

  String _statusText(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':    return 'Confirmed';
      case 'preparing':   return 'Preparing';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered':   return 'Delivered';
      case 'cancelled':   return 'Cancelled';
      default:            return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final bg    = _statusBg(order.status);
    final icon  = _statusIcon(order.status);
    final text  = _statusText(order.status);
    final fmt   = DateFormat('MMM dd • hh:mm a');

    return GestureDetector(
      onTap: () => context.push('/admin/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kRoseBorder, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x0EB22222), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 12),
                        const SizedBox(width: 4),
                        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextDark)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: _kLightRed, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_long_outlined, color: _kRed, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextDark)),
                        const SizedBox(height: 1),
                        Text(fmt.format(order.createdAt), style: const TextStyle(fontSize: 11, color: _kTextGrey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: _kTextGrey, size: 14),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: _kRoseBorder),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(icon: Icons.shopping_bag_outlined, label: '${order.items.length} item${order.items.length == 1 ? '' : 's'}'),
                  const SizedBox(width: 10),
                  _InfoChip(
                    icon: order.paymentMethod == 'COD' ? Icons.money_outlined : Icons.qr_code_scanner_rounded,
                    label: order.paymentMethod,
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kRoseBorder, width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kTextMid),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: _kTextMid, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── EMPTY ORDERS CARD ────────────────────────────────────────────
class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kRoseBorder, width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: _kRoseBorder),
          SizedBox(height: 10),
          Text('No orders yet', style: TextStyle(color: _kTextGrey, fontSize: 14, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('New orders will appear here', style: TextStyle(color: _kTextGrey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── ERROR CARD ───────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kLightRed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kRoseBorder, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: _kRed, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: _kDarkRed, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Retry', style: TextStyle(color: _kWhite, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}