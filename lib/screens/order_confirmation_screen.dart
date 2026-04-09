import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';

// ─── DESIGN TOKENS (Matching HomeScreen) ─────────────────────────────
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
// ─────────────────────────────────────────────────────────────────────

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Clear cart once confirmation screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).clearCart();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Order ID passed as extra from checkout navigation
    final orderId = GoRouterState.of(context).extra as String?;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── SUCCESS ICON ANIMATION ────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGreen, _kGreenBright],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _kWhite,
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── HEADLINE TEXT ─────────────────────────────────────────
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thank you for shopping with Triveni.\nYour package is on the way!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _kTextMid,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // ── ORDER ID TICKET ───────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kRoseBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: _kTextGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kLightRed,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Processing',
                              style: TextStyle(
                                color: _kRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'ORDER ID',
                              style: TextStyle(
                                fontSize: 10,
                                color: _kTextGrey,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orderId ?? 'TRV-${DateTime.now().millisecond}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: _kTextDark,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kLightRed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.timer_outlined,
                              color: _kRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Delivery',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _kTextGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '8 - 12 Minutes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kTextDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── ACTION BUTTON (Matching HomeScreen Style) ───────────
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kDarkRed, _kRed]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _kRed.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined,
                            color: _kWhite, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Back to Home',
                          style: TextStyle(
                            color: _kWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}