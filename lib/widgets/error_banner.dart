import 'package:flutter/material.dart';

import '../core/constants.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          color: AppColors.danger,
        ),
      ),
    );
  }
}
