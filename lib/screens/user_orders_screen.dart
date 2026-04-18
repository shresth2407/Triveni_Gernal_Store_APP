import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/admin_order.dart';
import '../providers/service_providers.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed          = Color(0xFFDC143C);
const _kDarkRed      = Color(0xFFB22222);
const _kDeepRed      = Color(0xFF8B0000);
const _kLightRed     = Color(0xFFFFF0F0);
const _kRoseBorder   = Color(0xFFFFCDD2);
const _kBg           = Color(0xFFF4F4F6);
const _kWhite        = Colors.white;
const _kTextDark     = Color(0xFF1A1A1A);
const _kTextGrey     = Color(0xFF9E9E9E);
const _kTextMid      = Color(0xFF555555);
const _kGreenBright  = Color(0xFF43A047);
const _kGreenLight   = Color(0xFFE8F5E9);
const _kGreenBorder  = Color(0xFFA5D6A7);
const _kGreenDark    = Color(0xFF2E7D32);
const _kOrange       = Color(0xFFE65100);
const _kOrangeLight  = Color(0xFFFFF3E0);
const _kOrangeBorder = Color(0xFFFFCC80);
const _kBlue         = Color(0xFF1565C0);
const _kBlueLight    = Color(0xFFE3F2FD);
const _kBlueBorder   = Color(0xFF90CAF9);

// ─── ORDER STATUS ENUM ────────────────────────────────────────────
enum OrderStatus { confirmed, preparing, outForDelivery, delivered, cancelled }

extension OrderStatusX on String {
  OrderStatus get toStatus {
    switch (toLowerCase()) {
      case 'confirmed':        return OrderStatus.confirmed;
      case 'preparing':        return OrderStatus.preparing;
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered':        return OrderStatus.delivered;
      case 'cancelled':        return OrderStatus.cancelled;
      default:                 return OrderStatus.confirmed;
    }
  }
}

// ─── MAIN SCREEN ──────────────────────────────────────────────────
class UserOrdersScreen extends ConsumerStatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  ConsumerState<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends ConsumerState<UserOrdersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Animated SliverAppBar ──────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _kDarkRed,
              elevation: 0,
              leading: _AnimatedBackButton(onTap: () {
                HapticFeedback.lightImpact();
                context.pop();
              }),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _HeroHeader(ordersAsync: ordersAsync),
                  ),
                ),
              ),
            ),

            // ── Section Label ──────────────────────────────────────
            SliverToBoxAdapter(
              child: ordersAsync.maybeWhen(
                data: (orders) => orders.isEmpty
                    ? const SizedBox.shrink()
                    : _SectionLabel(count: orders.length),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // ── Content ────────────────────────────────────────────
            ordersAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _kRed,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _ErrorCard(
                    onRetry: () => ref.invalidate(userOrdersProvider)),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyOrdersCard(onShop: () => context.go('/home')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _AnimatedOrderCard(
                        order: orders[index],
                        index: index,
                      ),
                      childCount: orders.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ANIMATED BACK BUTTON ─────────────────────────────────────────
class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedBackButton({required this.onTap});

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kWhite, size: 16),
        ),
      ),
    );
  }
}

// ─── HERO HEADER ──────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final AsyncValue ordersAsync;
  const _HeroHeader({required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
    final count = ordersAsync.valueOrNull?.length ?? 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDeepRed, _kDarkRed, _kRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(right: -40, top: -50,
              child: _Orb(size: 180, opacity: 0.06)),
          Positioned(right: 55, bottom: 10,
              child: _Orb(size: 90, opacity: 0.04)),
          Positioned(left: -30, bottom: -40,
              child: _Orb(size: 130, opacity: 0.04)),
          Positioned(left: 90, top: 50,
              child: _Orb(size: 60, opacity: 0.03)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: _kWhite, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Orders',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _kWhite,
                                  letterSpacing: -0.3)),
                          Text('Track your purchases',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Stats banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kDarkRed, _kRed]),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                  color: _kRed.withOpacity(0.38),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: _kWhite, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                count == 0
                                    ? 'No orders yet'
                                    : '$count ${count == 1 ? 'Order' : 'Orders'} placed',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _kTextDark),
                              ),
                              const Text('Triveni General Store',
                                  style: TextStyle(
                                      fontSize: 11, color: _kTextGrey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kLightRed,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kRoseBorder, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: _kRed, size: 13),
                              SizedBox(width: 3),
                              Text('8 min',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kRed,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}

// ─── SECTION LABEL ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final int count;
  const _SectionLabel({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kDarkRed, _kRed],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Order History',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark)),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kLightRed,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kRoseBorder, width: 1.5),
            ),
            child: Text('$count total',
                style: const TextStyle(
                    fontSize: 11,
                    color: _kRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── ANIMATED ORDER CARD WRAPPER ──────────────────────────────────
class _AnimatedOrderCard extends StatefulWidget {
  final AdminOrder order;
  final int index;
  const _AnimatedOrderCard({required this.order, required this.index});

  @override
  State<_AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<_AnimatedOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    // Stagger by index
    Future.delayed(Duration(milliseconds: 100 + widget.index * 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: _OrderCard(order: widget.order),
        ),
      ),
    );
  }
}

// ─── ORDER CARD ───────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final AdminOrder order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _pressed = false;

  // ── Status helpers ───────────────────────────────────────────────
  OrderStatus get _status => widget.order.status.toStatus;

  Color get _statusColor {
    switch (_status) {
      case OrderStatus.confirmed:       return _kBlue;
      case OrderStatus.preparing:       return _kOrange;
      case OrderStatus.outForDelivery:  return _kOrange;
      case OrderStatus.delivered:       return _kGreenBright;
      case OrderStatus.cancelled:       return _kRed;
    }
  }

  Color get _statusBg {
    switch (_status) {
      case OrderStatus.confirmed:       return _kBlueLight;
      case OrderStatus.preparing:       return _kOrangeLight;
      case OrderStatus.outForDelivery:  return _kOrangeLight;
      case OrderStatus.delivered:       return _kGreenLight;
      case OrderStatus.cancelled:       return _kLightRed;
    }
  }

  Color get _statusBorder {
    switch (_status) {
      case OrderStatus.confirmed:       return _kBlueBorder;
      case OrderStatus.preparing:       return _kOrangeBorder;
      case OrderStatus.outForDelivery:  return _kOrangeBorder;
      case OrderStatus.delivered:       return _kGreenBorder;
      case OrderStatus.cancelled:       return _kRoseBorder;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case OrderStatus.confirmed:       return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:       return Icons.restaurant_rounded;
      case OrderStatus.outForDelivery:  return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:       return Icons.task_alt_rounded;
      case OrderStatus.cancelled:       return Icons.cancel_outlined;
    }
  }

  String get _statusText {
    switch (_status) {
      case OrderStatus.confirmed:       return 'Confirmed';
      case OrderStatus.preparing:       return 'Preparing';
      case OrderStatus.outForDelivery:  return 'Out for Delivery';
      case OrderStatus.delivered:       return 'Delivered';
      case OrderStatus.cancelled:       return 'Cancelled';
    }
  }

  // Progress step index (0-based, -1 for cancelled)
  int get _progressStep {
    switch (_status) {
      case OrderStatus.confirmed:       return 0;
      case OrderStatus.preparing:       return 1;
      case OrderStatus.outForDelivery:  return 2;
      case OrderStatus.delivered:       return 3;
      case OrderStatus.cancelled:       return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy • hh:mm a');

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kRoseBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0EB22222),
                blurRadius: _pressed ? 6 : 16,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Header ──────────────────────────────────
              _StatusHeader(
                statusColor: _statusColor,
                statusBg: _statusBg,
                statusBorder: _statusBorder,
                statusIcon: _statusIcon,
                statusText: _statusText,
                orderId: widget.order.id,
                date: fmt.format(widget.order.createdAt),
              ),

              // ── Progress Tracker (hide for cancelled) ──────────
              if (_status != OrderStatus.cancelled)
                _ProgressTracker(activeStep: _progressStep),

              // ── Body ───────────────────────────────────────────
              _CardBody(order: widget.order),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STATUS HEADER ────────────────────────────────────────────────
class _StatusHeader extends StatelessWidget {
  final Color statusColor, statusBg, statusBorder;
  final IconData statusIcon;
  final String statusText, orderId, date;

  const _StatusHeader({
    required this.statusColor,
    required this.statusBg,
    required this.statusBorder,
    required this.statusIcon,
    required this.statusText,
    required this.orderId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(19)),
        border: Border(bottom: BorderSide(color: statusBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: statusColor.withOpacity(0.3), width: 1),
            ),
            child: Icon(statusIcon, color: statusColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor)),
                const SizedBox(height: 1),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kTextGrey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kRoseBorder, width: 1.5),
            ),
            child: Text(
              '#${orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _kTextMid),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROGRESS TRACKER ─────────────────────────────────────────────
class _ProgressTracker extends StatelessWidget {
  final int activeStep; // 0=confirmed, 1=preparing, 2=outForDelivery, 3=delivered
  const _ProgressTracker({required this.activeStep});

  static const _steps = [
    (Icons.check_circle_outline_rounded, 'Confirmed'),
    (Icons.restaurant_rounded, 'Preparing'),
    (Icons.delivery_dining_rounded, 'On the way'),
    (Icons.task_alt_rounded, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < activeStep;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: isDone
                      ? const LinearGradient(
                      colors: [_kGreenBright, _kGreenBright])
                      : null,
                  color: isDone ? null : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          // Step dot
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < activeStep;
          final isActive = stepIndex == activeStep;
          final icon = _steps[stepIndex].$1;
          final label = _steps[stepIndex].$2;

          Color dotBg, dotBorder, iconColor;
          if (isDone) {
            dotBg = _kGreenBright;
            dotBorder = _kGreenBright;
            iconColor = Colors.white;
          } else if (isActive) {
            dotBg = _kLightRed;
            dotBorder = _kRed;
            iconColor = _kRed;
          } else {
            dotBg = Colors.white;
            dotBorder = const Color(0xFFE0E0E0);
            iconColor = _kTextGrey;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive)
                    _PulseRing(color: _kRed),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: dotBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: dotBorder, width: 2),
                    ),
                    child: Icon(
                      isDone ? Icons.check_rounded : icon,
                      size: 12,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isDone
                      ? _kGreenBright
                      : isActive
                      ? _kRed
                      : _kTextGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── PULSE RING ANIMATION ─────────────────────────────────────────
class _PulseRing extends StatefulWidget {
  final Color color;
  const _PulseRing({required this.color});

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _scale = Tween<double>(begin: 0.8, end: 1.8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.7, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CARD BODY ────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final AdminOrder order;
  const _CardBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount + meta row
          Row(
            children: [
              _MetaPill(
                icon: Icons.shopping_bag_outlined,
                label:
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
              ),
              const SizedBox(width: 8),
              _MetaPill(
                icon: order.paymentMethod == 'COD'
                    ? Icons.money_outlined
                    : Icons.qr_code_scanner_rounded,
                label: order.paymentMethod == 'COD'
                    ? 'Cash on Delivery'
                    : 'UPI Payment',
              ),
              const Spacer(),
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _kRed,
                    letterSpacing: -0.5),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Delivery address
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kLightRed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kRoseBorder, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: _kRed, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryLocation,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMid,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Items list
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kRoseBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.list_alt_rounded,
                        color: _kTextMid, size: 13),
                    SizedBox(width: 5),
                    Text('Items',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _kTextMid)),
                  ],
                ),
                const SizedBox(height: 10),
                ...order.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                            color: _kRed, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.name} × ${item.quantity}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: _kTextDark,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${item.lineTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _kTextDark),
                      ),
                    ],
                  ),
                )),
                if (order.items.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kLightRed,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kRoseBorder, width: 1),
                    ),
                    child: Text(
                      '+${order.items.length - 3} more items',
                      style: const TextStyle(
                          fontSize: 10,
                          color: _kRed,
                          fontWeight: FontWeight.w700),
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

// ─── META PILL ────────────────────────────────────────────────────
class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kRoseBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kTextMid, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _kTextMid,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────
class _EmptyOrdersCard extends StatefulWidget {
  final VoidCallback onShop;
  const _EmptyOrdersCard({required this.onShop});

  @override
  State<_EmptyOrdersCard> createState() => _EmptyOrdersCardState();
}

class _EmptyOrdersCardState extends State<_EmptyOrdersCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: child,
              ),
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: _kLightRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRoseBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    size: 46, color: _kRoseBorder),
              ),
            ),
            const SizedBox(height: 22),
            const Text('No orders yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            const Text('Start shopping to see your\norders appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kTextGrey, fontSize: 13, height: 1.55)),
            const SizedBox(height: 30),
            _PressableButton(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onShop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 15),
                decoration: BoxDecoration(
                  gradient:
                  const LinearGradient(colors: [_kDarkRed, _kRed]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: _kWhite, size: 18),
                    SizedBox(width: 8),
                    Text('Start Shopping',
                        style: TextStyle(
                            color: _kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
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

// ─── ERROR CARD ───────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _kLightRed,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kRoseBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kRed.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRoseBorder, width: 1.5),
                ),
                child: const Icon(Icons.error_outline,
                    color: _kRed, size: 32),
              ),
              const SizedBox(height: 14),
              const Text('Failed to load orders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _kDarkRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(height: 6),
              const Text('Please check your connection\nand try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _kTextGrey, fontSize: 12, height: 1.5)),
              const SizedBox(height: 22),
              _PressableButton(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onRetry();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    gradient:
                    const LinearGradient(colors: [_kDarkRed, _kRed]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kRed.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: _kWhite, size: 16),
                      SizedBox(width: 6),
                      Text('Retry',
                          style: TextStyle(
                              color: _kWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PRESSABLE BUTTON (scale on press) ───────────────────────────
class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}