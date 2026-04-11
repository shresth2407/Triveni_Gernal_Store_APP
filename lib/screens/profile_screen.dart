import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_providers.dart';

const _kRed = Color(0xFFDC143C);
const _kDarkRed = Color(0xFFB22222);
const _kLightRed = Color(0xFFFFF0F0);
const _kRoseBorder = Color(0xFFFFCDD2);
const _kBg = Color(0xFFF7F7F7);
const _kWhite = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextGrey = Color(0xFF9E9E9E);
const _kGreen = Color(0xFF4CAF50);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;

      // Get current location address
      final locationAddress = ref.read(locationProvider).address ?? '';

      await ref.read(profileServiceProvider).updateProfile(
            user.uid,
            _nameController.text.trim(),
            _phoneController.text.trim(),
            locationAddress,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kWhite,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kTextDark,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (!_isEditing && profileAsync.hasValue && profileAsync.value != null && profileAsync.value!.isComplete)
            IconButton(
              icon: const Icon(Icons.edit, color: _kRed),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
        data: (profile) {
          // Initialize controllers with profile data
          if (profile != null && !_isEditing) {
            _nameController.text = profile.name;
            _phoneController.text = profile.phoneNumber;
          }

          // Get location from locationProvider
          final locationState = ref.watch(locationProvider);
          final currentAddress = locationState.address ?? 'No address set';
          final hasProfile = profile != null && profile.isComplete;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // First-time setup message
                if (!hasProfile) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kLightRed,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kRoseBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline, color: _kRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Please complete your profile to start shopping',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kDarkRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _kLightRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kRoseBorder, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: _kRed,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email (read-only)
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_outlined, color: _kTextGrey, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user?.email ?? 'No email',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name
                        const Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing || !hasProfile,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person_outline, color: _kRed),
                            filled: true,
                            fillColor: (_isEditing || !hasProfile) ? _kWhite : _kBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kRed, width: 2),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder.withOpacity(0.3)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Phone Number
                        const Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing || !hasProfile,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter 10-digit phone number',
                            prefixIcon: const Icon(Icons.phone_outlined, color: _kRed),
                            filled: true,
                            fillColor: (_isEditing || !hasProfile) ? _kWhite : _kBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kRed, width: 2),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _kRoseBorder.withOpacity(0.3)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length != 10) {
                              return 'Phone number must be 10 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Delivery Address (Read-only, managed via location screen)
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kRoseBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: _kRed, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentAddress,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/location?from=profile'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _kWhite,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _kRed, width: 1.5),
                                  ),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save/Cancel Buttons
                        if (_isEditing || !hasProfile) ...[
                          Row(
                            children: [
                              if (_isEditing && hasProfile)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isEditing = false;
                                              _nameController.text = profile!.name;
                                              _phoneController.text = profile.phoneNumber;
                                              // _addressController.text = profile.address;
                                            });
                                          },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: BorderSide(color: _kRoseBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _kTextDark,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isEditing && hasProfile) const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kRed,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _kWhite,
                                          ),
                                        )
                                      : Text(
                                          hasProfile ? 'Save Changes' : 'Save Profile',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _kWhite,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Continue Shopping Button (only show if profile is complete and not editing)
                if (hasProfile && !_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.shopping_bag_outlined, color: _kWhite),
                      label: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kWhite,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Logout Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: _kRed),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: _kRed, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
