import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../widgets/rnz_button.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, required this.onRecovered});

  final VoidCallback onRecovered;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _resetting = false;
  String? _error;

  Future<void> _reset() async {
    setState(() {
      _resetting = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) setState(() => _resetting = false);
      widget.onRecovered();
    } catch (e) {
      if (mounted) {
        setState(() {
          _resetting = false;
          _error = 'Gagal mengatur ulang data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.ivory,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Data Lokal Rusak',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Penyimpanan lokal perangkat tidak dapat dibaca atau telah mengalami kerusakan data. '
                      'Silakan atur ulang data lokal perangkat untuk melanjutkan menggunakan aplikasi.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    RnzButton(
                      key: const Key('recovery-reset-button'),
                      label: 'Atur Ulang Data',
                      loading: _resetting,
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
