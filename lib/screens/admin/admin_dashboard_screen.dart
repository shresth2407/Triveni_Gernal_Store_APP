import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
const _kGreenBright = Color(0xFF43A047);
const _kGreenLight  = Color(0xFFE8F5E9);

// ═════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD SCREEN
// ═════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends ConsumerState<AdminDashboardScreen> {
  bool _isSeeding = false;

  Future<void> _seedData() async {
    setState(() => _isSeeding = true);
    HapticFeedback.mediumImpact();

    try {
      final result =
      await ref.read(seedServiceProvider).seedData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Seeded ${result.categoriesSeeded} categories & '
                '${result.productsSeeded} products',
          ),
          backgroundColor: _kGreenBright,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seed failed: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(adminAuthServiceProvider).signOut();
    if (!mounted) return;
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,

        // ── APP BAR ─────────────────────────────────────────────
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
              // Admin logo circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kDarkRed, _kRed]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: _kWhite, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _kTextDark,
                    ),
                  ),
                  Text(
                    'Triveni General Store',
                    style: TextStyle(
                        fontSize: 10,
                        color: _kTextGrey,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: _logout,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kLightRed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRoseBorder, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: _kRed, size: 14),
                    SizedBox(width: 4),
                    Text('Logout',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kRed,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── BODY ─────────────────────────────────────────────────
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── WELCOME CARD ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDarkRed, _kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -16,
                      top: -16,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👋 Welcome Back!',
                          style: TextStyle(
                            color: _kWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your store from here.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MiniStat(
                                icon: Icons.bolt,
                                label: 'Express',
                                value: '8 mins'),
                            const SizedBox(width: 16),
                            _MiniStat(
                                icon: Icons.storefront_outlined,
                                label: 'Store',
                                value: 'Online'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── SECTION LABEL ──────────────────────────────────
              _SectionLabel(title: 'Manage Store'),

              const SizedBox(height: 10),

              // ── NAV TILES GRID ─────────────────────────────────
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
                    gradient: [
                      const Color(0xFF1565C0),
                      const Color(0xFF1E88E5)
                    ],
                    onTap: () => context.push('/admin/products'),
                  ),
                  _NavCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    subtitle: 'Track & update',
                    gradient: [
                      const Color(0xFF2E7D32),
                      const Color(0xFF43A047)
                    ],
                    onTap: () => context.push('/admin/orders'),
                  ),
                  _NavCard(
                    icon: Icons.local_offer_rounded,
                    title: 'Discounts',
                    subtitle: 'Offers & coupons',
                    gradient: [
                      const Color(0xFF6A1B9A),
                      const Color(0xFF8E24AA)
                    ],
                    onTap: () => context.push('/admin/discounts'),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── SECTION LABEL ──────────────────────────────────
              _SectionLabel(title: 'Database'),

              const SizedBox(height: 10),

              // ── SEED DATA CARD ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kRoseBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0EB22222),
                        blurRadius: 10,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _kLightRed,
                          borderRadius: BorderRadius.circular(14),
                          border:
                          Border.all(color: _kRoseBorder, width: 1.5),
                        ),
                        child: const Icon(Icons.storage_rounded,
                            color: _kRed, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seed Sample Data',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _kTextDark)),
                            SizedBox(height: 2),
                            Text(
                                'Populate categories & products\nfor testing',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _kTextGrey,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _isSeeding ? null : _seedData,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSeeding
                                  ? [
                                const Color(0xFFCC5555),
                                const Color(0xFFCC5555)
                              ]
                                  : [_kDarkRed, _kRed],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSeeding
                                ? []
                                : [
                              BoxShadow(
                                  color: _kRed.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3)),
                            ],
                          ),
                          child: _isSeeding
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kWhite),
                          )
                              : const Text('Seed',
                              style: TextStyle(
                                  color: _kWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── QUICK TIPS CARD ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kGreenLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFA5D6A7), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates_outlined,
                            color: _kGreenBright, size: 18),
                        SizedBox(width: 8),
                        Text('Quick Tips',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _kGreen)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _TipRow(
                        text:
                        'Add categories first before adding products.'),
                    _TipRow(
                        text:
                        'Use Seed Data only once for fresh setup.'),
                    _TipRow(
                        text:
                        'Update order status promptly to notify customers.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// MINI STAT  (inside welcome card)
// ═════════════════════════════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kWhite, size: 13),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  color: _kWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// SECTION LABEL
// ═════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_kDarkRed, _kRed],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kTextDark)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// NAV CARD  (2×2 grid)
// ═════════════════════════════════════════════════════════════════
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: _kWhite, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _kWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron
            Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.5), size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TIP ROW
// ═════════════════════════════════════════════════════════════════
class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: _kGreenBright, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: _kGreen,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}