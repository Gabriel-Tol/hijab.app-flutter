import 'package:flutter/material.dart';

import '../core/constants.dart';

enum DialogType { warning, danger, info, success }

/// Reusable confirm dialog with icon, styled title & subtitle.
Future<bool> showRnzConfirm(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  String cancelLabel = 'Batal',
  String confirmLabel = 'Ya',
  DialogType type = DialogType.warning,
  Key? confirmKey,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (ctx, a1, a2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a1, child: child),
      );
    },
    pageBuilder: (ctx, _, __) => _RnzConfirmDialog(
      title: title,
      message: message,
      content: content,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      type: type,
      confirmKey: confirmKey,
    ),
  );
  return result ?? false;
}

class _RnzConfirmDialog extends StatelessWidget {
  const _RnzConfirmDialog({
    required this.title,
    this.message,
    this.content,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.type,
    this.confirmKey,
  });

  final String title;
  final String? message;
  final Widget? content;
  final String cancelLabel;
  final String confirmLabel;
  final DialogType type;
  final Key? confirmKey;

  Color get _accentColor {
    switch (type) {
      case DialogType.danger:
        return AppColors.danger;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.success:
        return AppColors.success;
      case DialogType.info:
        return AppColors.forest;
    }
  }

  IconData get _icon {
    switch (type) {
      case DialogType.danger:
        return Icons.warning_amber_rounded;
      case DialogType.warning:
        return Icons.help_outline_rounded;
      case DialogType.success:
        return Icons.check_circle_outline_rounded;
      case DialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _accentColor, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (content != null)
                content!
              else if (message != null)
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: confirmKey,
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.small),
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
