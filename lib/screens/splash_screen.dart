import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/local_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final store = context.read<LocalStore>();
      context.go(store.onboardingSeen ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'RnZ',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ivory,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'RnZ Store',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Hijab tenun pilihan dari Pontianak.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
