
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/service_providers.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────
const _kRed         = Color(0xFFDC143C);      // Brand Primary
const _kDarkRed     = Color(0xFFB22222);      // Brand Dark
const _kLightRed    = Color(0xFFFFF0F0);      // Subtle Backgrounds
const _kRoseBorder  = Color(0xFFFFCDD2);      // Borders
const _kBg          = Color(0xFFF9FAFB);      // Very Light Grey/White
const _kWhite       = Colors.white;
const _kTextDark    = Color(0xFF111827);      // Almost Black
const _kTextGrey    = Color(0xFF9CA3AF);      // Placeholder Grey
const _kTextMid     = Color(0xFF4B5563);      // Secondary Text
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
duration: const Duration(milliseconds: 700),
);

_slideAnimation = Tween<Offset>(
begin: const Offset(0, 0.2),
end: Offset.zero,
).animate(CurvedAnimation(
parent: _animController,
curve: Curves.easeOutBack,
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
_animController.reset();
_animController.forward();
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
// ── ANIMATED GROCERY BACKGROUND ──────────────────────────────
const _FloatingGroceryParticles(),

// ── MAIN CONTENT ─────────────────────────────────────────────
SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 420),
child: SlideTransition(
position: _slideAnimation,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// ── HEADER: CART & BRANDING ─────────────────────
const _GroceryCartHeader(),
const SizedBox(height: 32),

// ── TITLE ────────────────────────────────────────
Text(
_isLoginMode ? 'Welcome to Triveni' : 'Start Shopping',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 32,
fontWeight: FontWeight.w800,
color: _kTextDark,
letterSpacing: -1,
height: 1.2,
),
),
const SizedBox(height: 12),
Text(
_isLoginMode
? 'Sign in to get your groceries delivered.'
    : 'Create an account for faster checkout.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 15,
color: _kTextMid,
height: 0.5,
),
),

const SizedBox(height: 40),

// ── CARD CONTAINER ───────────────────────────────
Container(
padding: const EdgeInsets.all(32),
decoration: BoxDecoration(
color: _kWhite,
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 40,
offset: const Offset(0, 15),
),
],
),
child: Form(
key: _formKey,
child: Column(
children: [
_GroceryInput(
controller: _emailController,
label: 'Email',
icon: Icons.email_outlined,
validator: _validateEmail,
),
const SizedBox(height: 20),
_GroceryInput(
controller: _passwordController,
label: 'Password',
icon: Icons.lock_outline_rounded,
obscureText: true,
validator: _validatePassword,
),

if (_isLoginMode) ...[
const SizedBox(height: 6),
Align(
alignment: Alignment.centerRight,
child: TextButton(
onPressed: () {},
style: TextButton.styleFrom(
padding: EdgeInsets.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
child: const Text(
'Forgot Password?',
style: TextStyle(
color: _kRed,
fontWeight: FontWeight.w600,
),
),
),
),
],

if (_errorMessage != null) ...[
const SizedBox(height: 16),
_GroceryErrorBox(message: _errorMessage!),
],

const SizedBox(height: 28),

// ── SUBMIT BUTTON ────────────────────────
SizedBox(
width: double.infinity,
height: 56,
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
gradient: LinearGradient(
colors: _isLoading
? [Colors.grey.shade300, Colors.grey.shade400]
    : [_kDarkRed, _kRed],
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: _kRed.withOpacity(0.4),
blurRadius: 20,
offset: const Offset(0, 8),
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
_isLoginMode ? 'Sign In' : 'Create Account',
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

const SizedBox(height: 10),

const _GroceryDivider(),
const SizedBox(height: 10),
const _GrocerySocialButtons(),
],
),
),
),

const SizedBox(height: 32),

// ── FOOTER TOGGLE ───────────────────────────────
Center(
child: GestureDetector(
onTap: _isLoading ? null : _toggleMode,
child: RichText(
text: TextSpan(
style: const TextStyle(fontSize: 14, color: _kTextMid),
children: [
TextSpan(text: _isLoginMode ? 'New customer? ' : 'Existing customer? '),
TextSpan(
text: _isLoginMode ? 'Create an account' : 'Sign In',
style: const TextStyle(
color: _kRed,
fontWeight: FontWeight.w800,
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
// CUSTOM GROCERY WIDGETS
// ═════════════════════════════════════════════════════════════════════

// 1. Floating Particles for "Freshness" vibe
class _FloatingGroceryParticles extends StatefulWidget {
const _FloatingGroceryParticles();

@override
State<_FloatingGroceryParticles> createState() => _FloatingGroceryParticlesState();
}

class _FloatingGroceryParticlesState extends State<_FloatingGroceryParticles>
with SingleTickerProviderStateMixin {
late AnimationController _controller;

@override
void initState() {
super.initState();
_controller = AnimationController(
vsync: this,
duration: const Duration(seconds: 20),
)..repeat();
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return SizedBox.expand(
child: Stack(
children: [
// Blob 1
AnimatedBuilder(
animation: _controller,
builder: (context, child) {
return Positioned(
top: -50 + (50 * (0.5 + 0.5 * (_controller.value * 2 % 2 - 1))),
right: -50,
child: Container(
width: 250,
height: 250,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _kLightRed,
),
),
);
},
),
// Blob 2 (Bottom Left)
AnimatedBuilder(
animation: _controller,
builder: (context, child) {
return Positioned(
bottom: -60 + (40 * (0.5 + 0.5 * (-_controller.value * 2 % 2 - 1))),
left: -60,
child: Container(
width: 200,
height: 200,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _kRed.withOpacity(0.05),
),
),
);
},
),
// Decorative Square (Abstract Box)
Positioned(
top: 100,
left: 30,
child: Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: _kWhite,
borderRadius: BorderRadius.circular(10),
boxShadow: [
BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
],
),
child: Icon(Icons.inventory_2_outlined, size: 20, color: _kRed),
),
),
// Decorative Circle (Abstract Can)
Positioned(
bottom: 150,
right: 40,
child: Container(
width: 30,
height: 30,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _kWhite,
boxShadow: [
BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
],
),
child: Icon(Icons.circle_outlined, size: 20, color: _kRed),
),
),
],
),
);
}
}

// 2. Grocery Cart Illustration
class _GroceryCartHeader extends StatelessWidget {
const _GroceryCartHeader();

@override
Widget build(BuildContext context) {
return SizedBox(
height: 120,
child: Stack(
alignment: Alignment.center,
children: [
// Glow
Container(
width: 110,
height: 110,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: _kLightRed,
),
),
// Cart Body Construction
Transform.rotate(
angle: -0.1,
child: Container(
width: 90,
height: 90,
decoration: BoxDecoration(
color: _kRed.withOpacity(0.2),
borderRadius: BorderRadius.circular(20),
),
),
),
Container(
width: 85,
height: 85,
decoration: BoxDecoration(
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [_kRed, _kDarkRed],
),
borderRadius: BorderRadius.circular(22),
boxShadow: [
BoxShadow(
color: _kRed.withOpacity(0.3),
blurRadius: 20,
offset: const Offset(0, 10),
),
],
),
child: Stack(
children: [
// The Cart Icon
const Center(
child: Icon(Icons.shopping_cart_outlined, color: _kWhite, size: 40),
),
// Fresh Badge
Positioned(
top: 10,
right: 10,
child: Container(
padding: const EdgeInsets.all(4),
decoration: const BoxDecoration(
color: _kWhite,
shape: BoxShape.circle,
),
child: Icon(Icons.spa, size: 12, color: _kRed),
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

// 3. Modern Input
class _GroceryInput extends StatelessWidget {
final TextEditingController controller;
final String label;
final IconData icon;
final bool obscureText;
final String? Function(String?)? validator;

const _GroceryInput({
required this.controller,
required this.label,
required this.icon,
this.obscureText = false,
this.validator,
});

@override
Widget build(BuildContext context) {
return TextFormField(
controller: controller,
obscureText: obscureText,
validator: validator,
style: const TextStyle(
fontSize: 16,
color: _kTextDark,
fontWeight: FontWeight.w500,
),
decoration: InputDecoration(
labelText: label,
labelStyle: TextStyle(color: _kTextGrey, fontSize: 14),
prefixIcon: Icon(icon, color: _kRed),
filled: true,
fillColor: _kBg, // Light grey bg
contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: _kRed, width: 2),
),
errorBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
),
),
);
}
}

// 4. Error Box
class _GroceryErrorBox extends StatelessWidget {
final String message;
const _GroceryErrorBox({required this.message});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(
color: const Color(0xFFFFEBEE),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: const Color(0xFFEF9A9A)),
),
child: Row(
children: [
const Icon(Icons.error_outline, color: _kRed, size: 20),
const SizedBox(width: 12),
Expanded(
child: Text(
message,
style: const TextStyle(
color: Color(0xFFB71C1C),
fontSize: 13,
fontWeight: FontWeight.w500,
),
),
),
],
),
);
}
}

// 5. Social Login Buttons (Pills)
class _GrocerySocialButtons extends StatelessWidget {
const _GrocerySocialButtons();

@override
Widget build(BuildContext context) {
return Column(
children: [
// _SocialButton(
// icon: Icons.g_mobiledata,
// label: 'Continue with Google',
// onTap: () {},
// ),
// const SizedBox(height: 12),
// _SocialButton(
// icon: Icons.apple,
// label: 'Continue with Apple',
// onTap: () {},
// ),
],
);
}
}

class _SocialButton extends StatelessWidget {
final IconData icon;
final String label;
final VoidCallback onTap;

const _SocialButton({
required this.icon,
required this.label,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(16),
child: Container(
height: 50,
decoration: BoxDecoration(
color: _kWhite,
border: Border.all(color: Colors.grey.shade200),
borderRadius: BorderRadius.circular(16),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(icon, size: 24, color: _kTextDark),
const SizedBox(width: 12),
Text(
label,
style: const TextStyle(
color: _kTextDark,
fontSize: 14,
fontWeight: FontWeight.w600,
),
),
],
),
),
);
}
}

class _GroceryDivider extends StatelessWidget {
const _GroceryDivider();

@override
Widget build(BuildContext context) {
return Row(
children: [
const Expanded(child: Divider(color: _kRoseBorder)),
// Padding(
// padding: const EdgeInsets.symmetric(horizontal: 16.0),
// child: Text(
// 'or',
// style: TextStyle(color: _kTextGrey, fontSize: 12, fontWeight: FontWeight.w500),
// ),
// ),
const Expanded(child: Divider(color: _kRoseBorder)),
],
);
}
}
