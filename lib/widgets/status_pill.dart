import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/models/order.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OrderStatus.awaitingPayment => (
        AppColors.warning.withValues(alpha: 0.12),
        AppColors.warning,
      ),
      OrderStatus.paymentVerification => (
        AppColors.terracotta.withValues(alpha: 0.12),
        AppColors.terracotta,
      ),
      OrderStatus.processing => (
        AppColors.forest.withValues(alpha: 0.12),
        AppColors.forest,
      ),
      OrderStatus.shipped => (
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
      ),
      OrderStatus.completed => (
        AppColors.success.withValues(alpha: 0.16),
        AppColors.success,
      ),
      OrderStatus.cancelled => (
        AppColors.danger.withValues(alpha: 0.12),
        AppColors.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
