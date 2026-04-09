import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/service_providers.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────
const _kRed         = Color(0xFFDC143C);
const _kDarkRed     = Color(0xFFB22222);
const _kLightRed    = Color(0xFFFFF0F0);
const _kRoseBorder  = Color(0xFFFFCDD2);
const _kBg          = Color(0xFFF7F7F7);
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF1A1A1A);
const _kTextGrey    = Color(0xFF9E9E9E); // This is already Grey 600
const _kTextMid     = Color(0xFF555555);
// ────────────────────────────────────────────────────────────────────────

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Start slightly lower
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final email = value.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (!_isLoginMode && value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isLoginMode) {
        await authService.signIn(email, password);
      } else {
        await authService.signUp(email, password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapFirebaseError(e));
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No account found for this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists.';
      case 'invalid-email': return 'The email address is invalid.';
      case 'weak-password': return 'Password is too weak.';
      default: return e.message ?? 'Authentication failed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── BACKGROUND BLOBS (Subtle Gradient Decor) ─────────────
          const _BackgroundDecoration(),

          // ── MAIN CONTENT ─────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // ── CUSTOM ILLUSTRATION (Shopping Bag) ──────────
                      const _HeaderIllustration(),

                      const SizedBox(height: 32),

                      // ── WELCOME TEXT ────────────────────────────────
                      Text(
                        _isLoginMode ? 'Welcome Back!' : 'Create Account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoginMode
                            ? 'Please enter your details to sign in.'
                            : 'Start your journey with Triveni today.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _kTextMid,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── INPUTS WRAPPER ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _kWhite,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _ModernInput(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),
                            _ModernInput(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              validator: _validatePassword,
                            ),

                            // Forgot Password Link (Visual only for now)
                            if (_isLoginMode)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 24),
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _kRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBox(message: _errorMessage!),
                            ],

                            const SizedBox(height: 15),

                            // ── ACTION BUTTON ────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_kDarkRed, _kRed],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kRed.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(_kWhite),
                                      ),
                                    )
                                        : Text(
                                      _isLoginMode ? 'Sign In' : 'Sign Up',
                                      style: const TextStyle(
                                        color: _kWhite,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── TOGGLE TEXT ────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLoginMode ? "Don't have an account? " : 'Already a member? ',
                            style: const TextStyle(
                              color: _kTextGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isLoading ? null : _toggleMode,
                            child: Text(
                              _isLoginMode ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                color: _kRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// CUSTOM WIDGETS FOR PROFESSIONAL LOOK
// ═════════════════════════════════════════════════════════════════════

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Top Right Blob
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kRed.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom Left Blob
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kDarkRed.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Card (Shadow)
          Transform.translate(
            offset: const Offset(0, 8),
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Middle Card (Bag Body)
          Transform.translate(
            offset: const Offset(0, 4),
            child: Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Front Card (Main Bag)
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kDarkRed, _kRed],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kRed.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Handle
                Icon(Icons.shopping_bag_outlined, color: _kWhite, size: 40),
                SizedBox(height: 8),
                // Brand Badge
                Text(
                  'TRIVENI',
                  style: TextStyle(
                    color: _kWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
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

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _ModernInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          color: _kTextDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          // FIXED: Removed .shade600 as _kTextGrey is already a specific color
          labelStyle: TextStyle(color: _kTextGrey, fontSize: 13),
          prefixIcon: Icon(icon, color: _kRed, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kRed, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}