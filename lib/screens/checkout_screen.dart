import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart';
import '../models/cart_item.dart';
import '../models/order_request.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_providers.dart';




// ─── DESIGN TOKENS (Preserved) ─────────────────────────
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

class UpiAppModel {
  final String name;
  final String packageName;
  final UpiApplication? application; // null for fallback

  UpiAppModel({
    required this.name,
    required this.packageName,
    this.application,
  });
}

// ═════════════════════════════════════════════════════════════════
// CHECKOUT SCREEN
// ═════════════════════════════════════════════════════════════════
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'COD'; // 'COD' | 'UPI'
  bool   _isLoading     = false;
  String? _error;

  // ─── PLACE ORDER LOGIC ─────────────────────────────────
  Future<void> _placeOrder() async {
    // If UPI is selected, show UPI app selection dialog
    if (_paymentMethod == 'UPI') {
      await _handleUpiPayment();
      return;
    }

    // COD payment - proceed directly
    await _processCodOrder();
  }


  // Future<List<UpiAppModel>> getAvailableUpiApps() async {
  //   F _upiIndia = FlutterUpiIndia();
  //   List<UpiAppModel> result = [];
  //
  //   try {
  //     final apps = await _upiIndia.getAllUpiApps();
  //
  //     for (var app in apps) {
  //       result.add(
  //         UpiAppModel(
  //           name: app.name,
  //           packageName: app.packageName,
  //           application: app.upiApplication,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print("UPI detection error: $e");
  //   }
  //
  //   // 🔥 Fallback apps (IMPORTANT)
  //   final fallbackApps = [
  //     UpiAppModel(
  //         name: "Google Pay",
  //         packageName: "com.google.android.apps.nbu.paisa.user"),
  //     UpiAppModel(
  //         name: "PhonePe",
  //         packageName: "com.phonepe.app"),
  //     UpiAppModel(
  //         name: "Paytm",
  //         packageName: "net.one97.paytm"),
  //   ];
  //
  //   // Add fallback if missing
  //   for (var fallback in fallbackApps) {
  //     final exists = result.any((e) => e.packageName == fallback.packageName);
  //     if (!exists) result.add(fallback);
  //   }
  //
  //   return result;
  // }

  Future<void> _handleUpiPayment() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      // final upiApps = await paymentService.getInstalledUpiApps();
      final upiApps =  await UpiPay.getInstalledUpiApplications();

      // final UpiIndia _upiIndia = UpiIndia();
      //
      // List<UpiApp> apps = await _upiIndia.getAllUpiApps();

      for (var app in upiApps) {
        print(app.packageName);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (upiApps.isEmpty) {
        setState(() => _error = 'No UPI apps found. Please install a UPI app or use Cash on Delivery.');
        return;
      }

      // Show UPI app selection dialog
      final selectedAppMeta = await showDialog<ApplicationMeta>(
        context: context,
        builder: (context) => _UpiAppSelectionDialog(apps: upiApps),
      );

      if (selectedAppMeta == null) return; // User cancelled

      // Initiate UPI payment
      await _processUpiPayment(selectedAppMeta);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load UPI apps: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _processUpiPayment(ApplicationMeta appMeta) async {
    setState(() { _isLoading = true; _error = null; });

    final cartState    = ref.read(cartProvider);
    final location     = ref.read(locationProvider).address ?? '';
    final user         = ref.read(authStateProvider).valueOrNull;
    final orderService = ref.read(orderServiceProvider);
    final paymentService = ref.read(paymentServiceProvider);
    final profileService = ref.read(profileServiceProvider);
    final grand = cartState.total + (cartState.total >= 149 ? 0.0 : 30.0);

    try {
      // Get user profile
      final profile = await profileService.getUserProfile(user?.uid ?? '');
      
      if (profile == null || !profile.isComplete) {
        if (!mounted) return;
        setState(() {
          _error = 'Please complete your profile (name, phone, address) before placing an order.';
          _isLoading = false;
        });
        return;
      }

      // First create the order
      final request = OrderRequest(
        userId:           user?.uid ?? '',
        userName:         profile.name,
        userPhone:        profile.phoneNumber,
        deliveryLocation: location,
        items:            cartState.items,
        totalAmount:      grand,
        paymentMethod:    'UPI',
      );

      final orderId = await orderService.placeOrder(request);

      // Then initiate UPI payment
      final response = await paymentService.initiateUpiPayment(
        app: appMeta.upiApplication,
        amount: grand.toStringAsFixed(2),
        orderId: orderId,
      );

      if (!mounted) return;

      // Check payment status
      if (response.status == UpiTransactionStatus.success) {
        context.go('/confirmation', extra: orderId);
      } else if (response.status == UpiTransactionStatus.failure) {
        setState(() {
          _error = 'Payment failed. Please try again or use Cash on Delivery.';
          _isLoading = false;
        });
      } else {
        // Submitted or other status
        setState(() {
          _error = 'Payment status: ${response.status}. Please check your UPI app.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Payment error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _processCodOrder() async {
    setState(() { _isLoading = true; _error = null; });

    final cartState    = ref.read(cartProvider);
    final location     = ref.read(locationProvider).address ?? '';
    final user         = ref.read(authStateProvider).valueOrNull;
    final orderService = ref.read(orderServiceProvider);
    final profileService = ref.read(profileServiceProvider);
    final grand = cartState.total + (cartState.total >= 149 ? 0.0 : 30.0);

    try {
      // Get user profile
      final profile = await profileService.getUserProfile(user?.uid ?? '');
      
      if (profile == null || !profile.isComplete) {
        if (!mounted) return;
        setState(() {
          _error = 'Please complete your profile (name, phone, address) before placing an order.';
          _isLoading = false;
        });
        return;
      }

      final request = OrderRequest(
        userId:           user?.uid ?? '',
        userName:         profile.name,
        userPhone:        profile.phoneNumber,
        deliveryLocation: location,
        items:            cartState.items,
        totalAmount:      grand,
        paymentMethod:    'COD',
      );

      final confirmedOrderId = await orderService.placeOrder(request);
      if (!mounted) return;
      context.go('/confirmation', extra: confirmedOrderId);
    } catch (e) {
      setState(() {
        _error     = 'Failed to place order: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final location  = ref.watch(locationProvider).address ?? '';
    final delivery  = cartState.total >= 149 ? 0.0 : 30.0;
    final savings   = cartState.total * 0.20;
    final grand     = cartState.total + delivery;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/cart');
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
        backgroundColor: _kBg,

        // ── MODERN APP BAR ───────────────────────────────────────
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          shadowColor: Colors.black.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
          titleSpacing: 16,
          title: Row(
            children: [
              _ModernIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => context.go('/cart'),
              ),
              const SizedBox(width: 16),
              const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _kLightRed,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: _kRed, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    '8 Mins',
                    style: TextStyle(
                        fontSize: 12,
                        color: _kDarkRed,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── BODY ─────────────────────────────────────────────────
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Increased padding for modern feel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── ORDER SUMMARY CARD ─────────────────────────
              _ModernSectionCard(
                icon: Icons.receipt_long_outlined,
                title: 'Order Summary',
                child: Column(
                  children: [
                    // Items List
                    ...cartState.items.map((ci) => _ModernOrderItemRow(cartItem: ci)),

                    const SizedBox(height: 16),

                    // Divider
                    Container(height: 1, color: _kRoseBorder.withOpacity(0.5)),
                    const SizedBox(height: 16),

                    // Calculations Area
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _BillRow(label: 'Item Total', value: '₹${cartState.total.toStringAsFixed(0)}'),
                          const SizedBox(height: 12),
                          _BillRow(
                            label: 'Delivery Fee',
                            value: delivery == 0 ? 'FREE' : '₹${delivery.toStringAsFixed(0)}',
                            valueColor: delivery == 0 ? _kGreenBright : _kTextDark,
                          ),
                          const SizedBox(height: 12),
                          _BillRow(
                            label: 'Discount (20%)',
                            value: '− ₹${savings.toStringAsFixed(0)}',
                            valueColor: _kGreenBright,
                          ),
                          const SizedBox(height: 12),
                          Container(height: 1, color: Colors.black.withOpacity(0.05)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kTextDark)),
                              Text('₹${grand.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: _kRed)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── DELIVERY ADDRESS CARD ──────────────────────
              _ModernSectionCard(
                icon: Icons.location_on_outlined,
                title: 'Delivery Address',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _kLightRed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_outlined, color: _kRed, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HOME',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _kRed,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(
                              location.isEmpty ? 'Set Location' : location,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark,
                                  height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/location?from=checkout'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _kWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kRoseBorder, width: 1),
                          ),
                          child: const Text('Change',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _kRed,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── PAYMENT METHOD CARD ────────────────────────
              _ModernSectionCard(
                icon: Icons.payment_outlined,
                title: 'Payment Method',
                child: Column(
                  children: [
                    _ModernPaymentOption(
                      value: 'COD',
                      groupValue: _paymentMethod,
                      icon: Icons.money_outlined,
                      title: 'Cash on Delivery',
                      subtitle: 'Pay when your order arrives',
                      onChanged: _isLoading ? null : (v) => setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    _ModernPaymentOption(
                      value: 'UPI',
                      groupValue: _paymentMethod,
                      icon: Icons.qr_code_scanner_rounded, // Changed icon for modern feel
                      title: 'UPI Payment',
                      subtitle: 'Pay via any UPI app',
                      onChanged: _isLoading ? null : (v) => setState(() => _paymentMethod = v!),
                    ),
                  ],
                ),
              ),

              // ── ERROR BANNER ───────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 20),
                _ModernErrorBanner(message: _error!, onRetry: _placeOrder),
              ],

              // ── FREE DELIVERY HINT ─────────────────────────
              if (cartState.total < 149) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _kGreenLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping_outlined, color: _kWhite, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add ₹${(149 - cartState.total).toStringAsFixed(0)} more for FREE delivery!',
                          style: const TextStyle(
                              fontSize: 13,
                              color: _kGreen,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20), // Extra bottom padding
            ],
          ),
        ),

        // ── MODERN PLACE ORDER BAR ───────────────────────────────
        bottomNavigationBar: _ModernPlaceOrderBar(
          isLoading: _isLoading,
          total: grand,
          paymentMethod: _paymentMethod,
          onPlaceOrder: _isLoading ? null : _placeOrder,
        ),
      ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN SECTION CARD
// ═════════════════════════════════════════════════════════════════
class _ModernSectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   child;

  const _ModernSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _kRed, size: 20),
                ),
                const SizedBox(width: 14),
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN ORDER ITEM ROW
// ═════════════════════════════════════════════════════════════════
class _ModernOrderItemRow extends StatelessWidget {
  final CartItem cartItem;

  const _ModernOrderItemRow({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Image with polished styling
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kRoseBorder.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                cartItem.item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: _kRoseBorder, size: 24)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                      height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${cartItem.item.price.toStringAsFixed(0)} x ${cartItem.quantity}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _kTextGrey,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Price
          Text(
            '₹${cartItem.lineTotal.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kTextDark),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BILL ROW (Simpler, Cleaner)
// ═════════════════════════════════════════════════════════════════
class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: _kTextMid, fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor ?? _kTextDark)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN PAYMENT OPTION
// ═════════════════════════════════════════════════════════════════
class _ModernPaymentOption extends StatelessWidget {
  final String        value;
  final String        groupValue;
  final IconData      icon;
  final String        title;
  final String        subtitle;
  final ValueChanged<String?>? onChanged;

  const _ModernPaymentOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kRed.withOpacity(0.04) : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kRed : _kRoseBorder.withOpacity(0.5),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? _kRed : _kWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? [BoxShadow(color: _kRed.withOpacity(0.25), blurRadius: 8, offset: Offset(0,4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0,2))],
              ),
              child: Icon(icon,
                  color: selected ? _kWhite : _kTextDark, size: 22),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: selected ? _kRed : _kTextDark)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: _kTextGrey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            // Custom Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kRed : _kWhite,
                border: Border.all(
                    color: selected ? _kRed : _kTextGrey.withOpacity(0.3), width: 2),
              ),
              child: selected
                  ? const Center(child: Icon(Icons.check, color: _kWhite, size: 14))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN ERROR BANNER
// ═════════════════════════════════════════════════════════════════
class _ModernErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ModernErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: _kRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    color: _kDarkRed,
                    fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: _kWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MODERN PLACE ORDER BAR
// ═════════════════════════════════════════════════════════════════
class _ModernPlaceOrderBar extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String paymentMethod;
  final VoidCallback? onPlaceOrder;

  const _ModernPlaceOrderBar({
    required this.isLoading,
    required this.total,
    required this.paymentMethod,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary Row (Above Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    color: _kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    color: _kTextDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main CTA Button
            GestureDetector(
              onTap: onPlaceOrder,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoading
                        ? [Colors.grey.shade300, Colors.grey.shade300]
                        : [_kDarkRed, _kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: _kRed.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: _kWhite),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        paymentMethod == 'COD'
                            ? Icons.money_outlined
                            : Icons.qr_code_scanner_rounded,
                        color: _kWhite,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Place Order',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER: MODERN ICON BUTTON (Back Button) ─────────────────────
class _ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModernIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _kTextDark, size: 18),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════
// UPI APP SELECTION DIALOG
// ═════════════════════════════════════════════════════════════════
class _UpiAppSelectionDialog extends StatelessWidget {
  final List<ApplicationMeta> apps;

  const _UpiAppSelectionDialog({required this.apps});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payment, color: _kRed, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Select UPI App',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: _kTextGrey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred UPI app to complete the payment',
              style: TextStyle(
                fontSize: 13,
                color: _kTextMid,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return _UpiAppTile(
                    app: app,
                    onTap: () => Navigator.of(context).pop(app),
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

// ═════════════════════════════════════════════════════════════════
// UPI APP TILE
// ═════════════════════════════════════════════════════════════════
class _UpiAppTile extends StatelessWidget {
  final ApplicationMeta app;
  final VoidCallback onTap;

  const _UpiAppTile({required this.app, required this.onTap});

  String _getAppDisplayName(ApplicationMeta appMeta) {
    // Map package names to display names
    final Map<String, String> appNames = {
      'com.google.android.apps.nbu.paisa.user': 'Google Pay',
      'net.one97.paytm': 'Paytm',
      'in.org.npci.upiapp': 'BHIM',
      'com.phonepe.app': 'PhonePe',
      'com.amazon.mobile.shopping': 'Amazon Pay',
      'com.whatsapp': 'WhatsApp',
      'com.dreamplug.androidapp': 'CRED',
      'com.mobikwik_new': 'MobiKwik',
      'com.freecharge.android': 'FreeCharge',
    };

    return appNames[appMeta.upiApplication.androidPackageName] ?? appMeta.upiApplication.appName;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getAppDisplayName(app);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRoseBorder, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // App icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: app.iconImage(48),
                  ),
                ),
                const SizedBox(width: 16),
                // App name
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                ),
                // Arrow icon
                const Icon(Icons.arrow_forward_ios, color: _kTextGrey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
