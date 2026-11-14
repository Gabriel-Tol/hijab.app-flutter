import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/ids.dart';
import '../../data/models/address.dart';
import '../../data/models/master.dart';
import '../../data/models/order.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/order_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final String _idempotencyKey = newId('idem');

  Address? _address;
  PaymentMethod? _payment;
  List<PaymentMethod> _methods = const [];
  bool _submitting = false;
  String? _error;
  Map<String, String> _stockErrors = const {};

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthController>().user?.id;
    if (userId != null) {
      _address = context.read<ProfileRepository>().defaultAddress(userId);
    }
    _methods = context.read<CheckoutRepository>().activePaymentMethods();
    _payment = _methods.isEmpty ? null : _methods.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartController>().load();
    });
  }

  Future<void> _selectAddress() async {
    final id = await context.push<String>('/addresses?select=1');
    if (!mounted || id == null) return;
    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;
    setState(() {
      _address = context.read<ProfileRepository>().addressById(userId, id);
    });
  }

  Future<void> _submit() async {
    final cart = context.read<CartController>();
    final address = _address;
    final payment = _payment;
    if (cart.lines.isEmpty || address == null || payment == null) return;

    setState(() {
      _submitting = true;
      _error = null;
      _stockErrors = const {};
    });

    final result = await context.read<OrderController>().createOrder(
      addressId: address.id,
      paymentMethodId: payment.id,
      idempotencyKey: _idempotencyKey,
    );
    if (!mounted) return;

    if (!result.isOk) {
      setState(() {
        _submitting = false;
        _error = result.error!.message;
        _stockErrors = result.error!.fields;
      });
      return;
    }

    setState(() => _submitting = false);
    context.pushReplacement('/orders/${result.value!.id}/payment');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final userId = context.watch<AuthController>().user?.id;
    final summary = userId != null && _address != null
        ? context.read<CheckoutRepository>().summary(
            userId: userId,
            address: _address!,
          )
        : null;

    final blocked = cart.lines.isEmpty
        ? 'Keranjang masih kosong. Tambahkan produk sebelum checkout.'
        : _address == null
        ? 'Tambahkan alamat pengiriman terlebih dahulu.'
        : _methods.isEmpty
        ? 'Belum ada metode pembayaran aktif.'
        : null;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (blocked != null) ...[
                    ErrorBanner(message: blocked),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (_error != null) ...[
                    ErrorBanner(message: _error!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _addressCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _paymentCard(),
                  const SizedBox(height: AppSpacing.lg),
                  if (summary != null) _summary(summary),
                ],
              ),
            ),
          ),
          _bottomBar(cart, blocked),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final address = _address;
    return _card(
      title: 'Alamat Pengiriman',
      trailing: TextButton(
        key: const Key('checkout-change-address'),
        onPressed: _selectAddress,
        child: Text(address == null ? 'Tambah Alamat' : 'Ubah'),
      ),
      child: address == null
          ? const Text(
              'Belum ada alamat pengiriman.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.muted,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        address.label,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'Utama',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${address.recipientName} · ${address.recipientPhone}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${address.addressLine}, ${address.district}, '
                  '${address.city}, ${address.province} ${address.postalCode}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _paymentCard() {
    return _card(
      title: 'Metode Pembayaran',
      child: _methods.isEmpty
          ? const Text(
              'Belum ada metode pembayaran aktif.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.muted,
              ),
            )
          : Column(
              children: [
                for (final method in _methods)
                  _paymentTile(method, method.id == _payment?.id),
              ],
            ),
    );
  }

  Widget _paymentTile(PaymentMethod method, bool selected) {
    return InkWell(
      key: Key('payment-${method.id}'),
      onTap: () => setState(() => _payment = method),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.terracotta : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.terracotta : AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${method.provider} · ${method.type.label}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                method.accountNo,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'a.n. ${method.accountName}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summary(CheckoutSummary summary) {
    return _card(
      title: 'Ringkasan Pesanan',
      child: Column(
        children: [
          for (final line in summary.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name} · ${line.variant.label}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${line.qty}×',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatRupiah(line.lineTotal),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  if (_stockErrors[line.variant.id] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _stockErrors[line.variant.id]!,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg, color: AppColors.line),
          _costRow('Subtotal', formatRupiah(summary.subtotal)),
          const SizedBox(height: AppSpacing.sm),
          _costRow(
            'Ongkir',
            summary.shippingNote ?? formatRupiah(summary.shippingCost),
            key: summary.shippingNote == null
                ? null
                : const Key('checkout-shipping-note'),
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.line),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(summary.total),
                key: const Key('checkout-total'),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {Key? key}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            key: key,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(CartController cart, String? blocked) {
    final canSubmit =
        blocked == null &&
        cart.lines.isNotEmpty &&
        _address != null &&
        _payment != null;
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
        child: RnzButton(
          key: const Key('checkout-submit'),
          label: 'Buat Pesanan',
          loading: _submitting,
          onPressed: canSubmit ? _submit : null,
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
