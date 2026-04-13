import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/admin/admin_service_providers.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────
const _kRed        = Color(0xFFDC143C);
const _kDarkRed    = Color(0xFFB22222);
const _kLightRed   = Color(0xFFFFF0F0);
const _kRoseBorder = Color(0xFFFFCDD2);
const _kBg         = Color(0xFFF7F7F7);
const _kWhite      = Colors.white;
const _kTextDark   = Color(0xFF1A1A1A);
const _kTextGrey   = Color(0xFF9E9E9E);
const _kTextMid    = Color(0xFF555555);
const _kGreenLight = Color(0xFFE8F5E9);
const _kGreen      = Color(0xFF2E7D32);

// ═════════════════════════════════════════════════════════════════
// ADMIN LOGIN SCREEN
// ═════════════════════════════════════════════════════════════════
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();

  bool    _isLoading    = false;
  bool    _obscurePass  = true;
  String? _errorMessage;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    setState(() { _isLoading = true; _errorMessage = null; });

    final adminAuthService = ref.read(adminAuthServiceProvider);

    try {
      await adminAuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final user = adminAuthService.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
          _isLoading = false;
        });
        return;
      }

      final isAdmin = await adminAuthService.isAdmin(user.uid);
      if (!mounted) return;

      if (isAdmin) {
        context.go('/admin/dashboard');
      } else {
        await adminAuthService.signOut();
        setState(() {
          _errorMessage = 'Access denied: not an admin account.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            e.message ?? 'Authentication error. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
        'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            // ── Decorative top arc ─────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: ClipPath(
                clipper: _ArcClipper(),
                child: Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kDarkRed, _kRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30, top: -30,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20, bottom: 20,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ─────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            // ── Logo circle ────────────────────
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: _kWhite,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _kRed.withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: _kRed, size: 40),
                            ),

                            const SizedBox(height: 14),

                            // ── Title ──────────────────────────
                            const Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: _kWhite,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Triveni General Store',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── White form card ────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: _kWhite,
                                borderRadius:
                                BorderRadius.circular(24),
                                border: Border.all(
                                    color: _kRoseBorder, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    _kRed.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sign In',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                            FontWeight.w900,
                                            color: _kTextDark)),
                                    const SizedBox(height: 4),
                                    const Text(
                                        'Enter your admin credentials',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _kTextGrey)),

                                    const SizedBox(height: 22),

                                    // ── Email field ───────────
                                    _FieldLabel(label: 'Email'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType
                                          .emailAddress,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: _kTextDark),
                                      decoration: _inputDeco(
                                        hint:
                                        'admin@triveni.com',
                                        icon: Icons
                                            .email_outlined,
                                      ),
                                      validator: (v) {
                                        if (v == null ||
                                            v.trim().isEmpty) {
                                          return 'Please enter your email.';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Please enter a valid email.';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // ── Password field ────────
                                    _FieldLabel(
                                        label: 'Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller:
                                      _passwordController,
                                      obscureText: _obscurePass,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: _kTextDark),
                                      decoration: _inputDeco(
                                        hint: '••••••••',
                                        icon: Icons.lock_outline,
                                        suffix: GestureDetector(
                                          onTap: () => setState(
                                                  () => _obscurePass =
                                              !_obscurePass),
                                          child: Icon(
                                            _obscurePass
                                                ? Icons
                                                .visibility_off_outlined
                                                : Icons
                                                .visibility_outlined,
                                            color: _kTextGrey,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null ||
                                            v.isEmpty) {
                                          return 'Please enter your password.';
                                        }
                                        return null;
                                      },
                                    ),

                                    // ── Error message ─────────
                                    if (_errorMessage != null) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding:
                                        const EdgeInsets.all(
                                            12),
                                        decoration: BoxDecoration(
                                          color: _kLightRed,
                                          borderRadius:
                                          BorderRadius.circular(
                                              12),
                                          border: Border.all(
                                              color: _kRoseBorder,
                                              width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .error_outline,
                                                color: _kRed,
                                                size: 18),
                                            const SizedBox(
                                                width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                    color: _kDarkRed,
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight
                                                        .w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 22),

                                    // ── Sign In button ────────
                                    GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : _submit,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: double.infinity,
                                        padding: const EdgeInsets
                                            .symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _isLoading
                                                ? [
                                              const Color(
                                                  0xFFCC5555),
                                              const Color(
                                                  0xFFCC5555),
                                            ]
                                                : [_kDarkRed, _kRed],
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(
                                              16),
                                          boxShadow: _isLoading
                                              ? []
                                              : [
                                            BoxShadow(
                                              color: _kRed
                                                  .withOpacity(
                                                  0.4),
                                              blurRadius: 14,
                                              offset:
                                              const Offset(
                                                  0, 5),
                                            ),
                                          ],
                                        ),
                                        child: _isLoading
                                            ? const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child:
                                            CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: _kWhite,
                                            ),
                                          ),
                                        )
                                            : const Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                          children: [
                                            Icon(
                                                Icons
                                                    .login_rounded,
                                                color: _kWhite,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                color: _kWhite,
                                                fontSize: 15,
                                                fontWeight:
                                                FontWeight
                                                    .w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Dev shortcut ───────────────────
                            GestureDetector(
                              onTap: () =>
                                  context.go('/admin/dashboard'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _kWhite,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _kRoseBorder,
                                      width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.developer_mode_rounded,
                                        color: _kTextGrey,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    const Text('Skip to Dashboard',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _kTextGrey,
                                            fontWeight:
                                            FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Footer ─────────────────────────
                            Text(
                              'Triveni General Store © 2025',
                              style: const TextStyle(
                                  fontSize: 11, color: _kTextGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
      prefixIcon: Icon(icon, color: _kDarkRed, size: 20),
      suffixIcon: suffix != null
          ? Padding(
        padding: const EdgeInsets.only(right: 12),
        child: suffix,
      )
          : null,
      filled: true,
      fillColor: _kLightRed,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRoseBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRoseBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kRed, width: 2),
      ),
      errorStyle: const TextStyle(
          color: _kRed, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// FIELD LABEL
// ═════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _kTextMid,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// ARC CLIPPER  — decorative top background
// ═════════════════════════════════════════════════════════════════
class _ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 55);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 30,
      size.width,
      size.height - 55,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ArcClipper _) => false;
}