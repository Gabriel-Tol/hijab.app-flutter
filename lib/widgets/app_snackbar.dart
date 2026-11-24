import 'package:flutter/material.dart';

import '../core/constants.dart';

enum SnackType { success, error, info, undo }

/// Show a styled snackbar with icon, optional action, and close button.
void showRnzSnackBar(
  BuildContext context, {
  required String message,
  SnackType type = SnackType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      content: Row(
        children: [
          const SizedBox(width: 12),
          _icon(type),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13.5,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.terracotta,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              child: Text(actionLabel),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.surface),
            onPressed: () => messenger.hideCurrentSnackBar(),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    ),
  );
}

Widget _icon(SnackType type) {
  switch (type) {
    case SnackType.success:
      return const Icon(Icons.check_circle_rounded,
          color: Color(0xFF66BB6A), size: 20);
    case SnackType.error:
      return const Icon(Icons.error_rounded,
          color: Color(0xFFEF5350), size: 20);
    case SnackType.info:
      return const Icon(Icons.info_rounded,
          color: Color(0xFF42A5F5), size: 20);
    case SnackType.undo:
      return const Icon(Icons.replay_rounded,
          color: AppColors.terracotta, size: 20);
  }
}
