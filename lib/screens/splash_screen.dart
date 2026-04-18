import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:groicery_delivery/Utility/Utils.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';

const _kRed = Color(0xFF9F1C20);
const _kDarkRed = Color(0xFFB22222);
const _kWhite = Colors.white;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for 1 second minimum for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check auth state
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.valueOrNull != null;

    if (!isAuthenticated) {

      if(Utils.isAdmin){
        context.go('/admin/login');
      }else{
        context.go('/auth');
      }

      return;
    }

    // Check location state
    final locationState = ref.read(locationProvider);
    final hasLocation = locationState.address != null;

    if (!hasLocation && !Utils.isAdmin) {
      context.go('/location');
      return;
    }


    if(Utils.isAdmin){
      context.go('/admin/dashboard');
    }else{
      context.go('/home');
    }
    // All good, go to home

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              // decoration: BoxDecoration(
              //   color: _kWhite,
              //   borderRadius: BorderRadius.circular(30),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black.withOpacity(0.2),
              //       blurRadius: 20,
              //       offset: const Offset(0, 10),
              //     ),
              //   ],
              // ),
              child:  Image.asset("assets/images/icon.png"

              ),
            ),
            const SizedBox(height: 30),
            // App Name
            // const Text(
            //   'Triveni Express',
            //   style: TextStyle(
            //     fontSize: 32,
            //     fontWeight: FontWeight.w900,
            //     color: _kWhite,
            //     letterSpacing: -1,
            //   ),
            // ),
            // const SizedBox(height: 8),
            // const Text(
            //   'Groceries in 8 minutes',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.w600,
            //     color: _kWhite,
            //     letterSpacing: 0.5,
            //   ),
            // ),
            const SizedBox(height: 50),
            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_kWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
