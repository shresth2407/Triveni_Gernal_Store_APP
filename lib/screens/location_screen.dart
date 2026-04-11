import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/location_provider.dart';

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
// ─────────────────────────────────────────────────────────────────────

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with SingleTickerProviderStateMixin {
  final _addressController = TextEditingController();
  String? _validationError;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _detectGps() async {
    setState(() => _validationError = null);
    await ref.read(locationProvider.notifier).detectGps();

    final locationState = ref.read(locationProvider);
    if (locationState.address != null) {
      _addressController.text = locationState.address!;
    }
  }

  void _confirm() {
    final text = _addressController.text.trim();
    if (text.isEmpty) {
      setState(() => _validationError = 'Please enter a delivery address.');
      return;
    }
    setState(() => _validationError = null);
    ref.read(locationProvider.notifier).setManual(text);
    
    // Check if we came from checkout
    final uri = GoRouterState.of(context).uri;
    final fromCheckout = uri.queryParameters['from'] == 'checkout';
    
    if (fromCheckout) {
      context.go('/checkout');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final isLoading = locationState.isLoading;
    
    // Check if we came from checkout
    final uri = GoRouterState.of(context).uri;
    final fromCheckout = uri.queryParameters['from'] == 'checkout';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: fromCheckout ? AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kTextDark, size: 20),
          onPressed: () => context.go('/checkout'),
        ),
        title: const Text(
          'Change Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _kTextDark,
          ),
        ),
      ) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── MAP VISUALIZATION HEADER ───────────────────────────
                const _MapVisualizer(),

                const SizedBox(height: 32),

                // ── TITLE SECTION ───────────────────────────────────────
                const Text(
                  'Where should we\ndeliver?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your location to see available products and offers near you.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kTextMid,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── GPS BUTTON ──────────────────────────────────────────
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kRoseBorder, width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : _detectGps,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _kRed,
                                ),
                              )
                            else
                              const Icon(
                                Icons.near_me,
                                color: _kRed,
                                size: 22,
                              ),
                            const SizedBox(width: 12),
                            Text(
                              isLoading ? 'Locating...' : 'Use Current Location',
                              style: const TextStyle(
                                color: _kDarkRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (locationState.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationState.error!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── DIVIDER ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: _kRoseBorder)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR ENTER MANUALLY',
                        style: TextStyle(
                          color: _kTextGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: _kRoseBorder)),
                  ],
                ),

                const SizedBox(height: 24),

                // ── SEARCH BAR INPUT ─────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kRoseBorder, width: 1.5),
                  ),
                  child: TextField(
                    controller: _addressController,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_validationError != null) {
                        setState(() => _validationError = null);
                      }
                    },
                    onSubmitted: (_) => isLoading ? null : _confirm(),
                    style: const TextStyle(fontSize: 15, color: _kTextDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'House no, Area, Street...',
                      hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: _kDarkRed, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      errorText: _validationError,
                      errorStyle: const TextStyle(height: 0.8), // Compact error
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── CONFIRM BUTTON ───────────────────────────────────────
                GestureDetector(
                  onTap: isLoading ? null : _confirm,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kDarkRed, _kRed]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _kRed.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: _kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// CUSTOM MAP VISUALIZER (No external images required)
// ═════════════════════════════════════════════════════════════════
class _MapVisualizer extends StatelessWidget {
  const _MapVisualizer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Pattern (Simulating Map)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: CustomPaint(
              painter: _MapPainter(),
              size: const Size(double.infinity, 180),
            ),
          ),
          // Centered Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kDarkRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _kDarkRed.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Text(
                    'Delivery Area',
                    style: TextStyle(
                      color: _kWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // The Pin
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kWhite, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: _kWhite,
                    size: 24,
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

// Simple painter to draw map-like lines
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw some random "roads"
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.6, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.4, size.height), paint);

    // Draw "blocks"
    final blockPaint = Paint()..color = Colors.grey[200]!;
    canvas.drawRect(Rect.fromLTWH(20, 20, 50, 50), blockPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 70, size.height - 70, 50, 50), blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}