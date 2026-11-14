import 'package:flutter/material.dart';

import '../core/constants.dart';

enum RnzButtonVariant { primary, secondary, ghost }

class RnzButton extends StatelessWidget {
  const RnzButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = RnzButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final RnzButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final spinnerColor = variant == RnzButtonVariant.primary
        ? Colors.white
        : AppColors.forest;
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        : Text(label);

    final button = switch (variant) {
      RnzButtonVariant.primary => FilledButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      RnzButtonVariant.secondary => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      RnzButtonVariant.ghost => TextButton(
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.xl * 2,
      child: button,
    );
  }
}
