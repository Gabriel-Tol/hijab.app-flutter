import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/formatters.dart';
import '../../data/models/cart.dart';
import '../../state/cart_controller.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/rnz_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartController>().load();
    });
  }

  Future<void> _clear() async {
    final confirmed = await showRnzConfirm(
      context,
      title: 'Kosongkan keranjang?',
      message:
          'Semua produk di keranjang akan dihapus. Tindakan ini tidak dapat '
          'diurungkan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Kosongkan',
      type: DialogType.danger,
      confirmKey: const Key('cart-clear-confirm'),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CartController>().clear();
  }

  void _remove(CartLine line) {
    final cart = context.read<CartController>();
    final messenger = ScaffoldMessenger.of(context);
    final qty = line.qty;
    messenger.hideCurrentSnackBar();
    cart.remove(line.variant.id);
    showRnzSnackBar(
      context,
      message: '${line.product.name} dihapus.',
      duration: AppConstants.undoWindow,
      type: SnackType.info,
      onAction: () {
        final result = cart.add(line.variant.id, qty: qty);
        if (!result.isOk) {
          showRnzSnackBar(
            context,
            message:
                result.error!.fields[line.variant.id] ?? result.error!.message,
            type: SnackType.error,
          );
        }
      },
      actionLabel: 'Urungkan',
    );
  }

  void _setQty(CartLine line, int qty) {
    final result = context.read<CartController>().setQty(line.variant.id, qty);
    if (result.isOk || !mounted) return;
    showRnzSnackBar(
      context,
      message:
          result.error!.fields[line.variant.id] ?? result.error!.message,
      type: SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (cart.lines.isNotEmpty)
            TextButton(
              key: const Key('cart-clear'),
              onPressed: _clear,
              child: const Text('Kosongkan'),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: cart.lines.isEmpty
          ? EmptyState(
              title: 'Keranjang Anda masih kosong',
              message: 'Jelajahi koleksi dan tambahkan hijab favorit Anda.',
              actionLabel: 'Mulai Belanja',
              onAction: () => context.go('/home'),
            )
          : Column(
              children: [
                Expanded(child: _lines(cart)),
                _bottomPanel(cart),
              ],
            ),
    );
  }

  Widget _lines(CartController cart) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      itemCount: cart.lines.length + (cart.warnings.isEmpty ? 0 : 1),
      separatorBuilder: (context, index) =>
          const Divider(height: AppSpacing.xl, color: AppColors.line),
      itemBuilder: (context, index) {
        if (cart.warnings.isNotEmpty) {
          if (index == 0) return _warnings(cart.warnings);
          index -= 1;
        }
        final line = cart.lines[index];
        return _line(line);
      },
    );
  }

  Widget _warnings(List<String> warnings) {
    return Container(
      key: const Key('cart-warning'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final warning in warnings)
            Text(
              warning,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                height: 1.5,
                color: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(CartLine line) {
    final product = line.product;
    return Row(
      key: Key('cart-line-${line.variant.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: SizedBox(
            width: 84,
            height: 104,
            child: product.images.isEmpty
                ? const ColoredBox(color: AppColors.line)
                : Image.asset(
                    product.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.line),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('cart-remove-${line.variant.id}'),
                    tooltip: 'Hapus ${product.name}',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _remove(line),
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Text(
                line.variant.label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatRupiah(product.price)} / item',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  QuantityStepper(
                    value: line.qty,
                    min: 1,
                    max: line.variant.stock,
                    onChanged: (value) => _setQty(line, value),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(line.lineTotal),
                    key: Key('cart-line-total-${line.variant.id}'),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomPanel(CartController cart) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupiah(cart.subtotal),
                  key: const Key('cart-subtotal'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RnzButton(
              key: const Key('cart-checkout'),
              label: 'Lanjut ke Checkout',
              onPressed: () => context.push('/checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
