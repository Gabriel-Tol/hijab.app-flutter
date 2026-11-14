import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../core/result.dart';
import '../../data/models/order.dart';
import '../../state/order_controller.dart';
import '../../widgets/copy_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';
import '../../widgets/status_pill.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _rejectReason = TextEditingController();
  final _cancelReason = TextEditingController();
  final _tracking = TextEditingController();

  String _courier = AppConstants.couriers.first;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant OrderDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _load();
    }
  }

  @override
  void dispose() {
    _rejectReason.dispose();
    _cancelReason.dispose();
    _tracking.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<OrderController>().loadDetail(widget.orderId);
    if (mounted) setState(() => _loading = false);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmKey,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: Key(confirmKey),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _cancel() async {
    final confirmed = await _confirm(
      title: 'Batalkan pesanan?',
      message: 'Pesanan akan dibatalkan dan stok produk dikembalikan.',
      confirmKey: 'cancel-confirm',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final result = await context.read<OrderController>().cancel(widget.orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    _report(result, 'Pesanan dibatalkan.');
  }

  Future<void> _complete() async {
    final confirmed = await _confirm(
      title: 'Pesanan diterima?',
      message: 'Konfirmasi bahwa pesanan sudah Anda terima dengan baik.',
      confirmKey: 'complete-confirm',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final result = await context.read<OrderController>().complete(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _report(result, 'Pesanan selesai.');
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    final result = await context.read<OrderController>().adminApprove(
      widget.orderId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _report(result, 'Pembayaran disetujui.');
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    final result = await context.read<OrderController>().adminReject(
      widget.orderId,
      _rejectReason.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) _rejectReason.clear();
    _report(result, 'Pembayaran ditolak.');
  }

  Future<void> _ship() async {
    setState(() => _busy = true);
    final result = await context.read<OrderController>().adminShip(
      widget.orderId,
      _courier,
      _tracking.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) _tracking.clear();
    _report(result, 'Pesanan dikirim.');
  }

  Future<void> _adminCancel() async {
    setState(() => _busy = true);
    final result = await context.read<OrderController>().adminCancel(
      widget.orderId,
      _cancelReason.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isOk) _cancelReason.clear();
    _report(result, 'Pesanan dibatalkan.');
  }

  void _report(AppResult<void> result, String success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.isOk ? success : result.error!.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    final order = controller.selected?.id == widget.orderId
        ? controller.selected
        : null;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? EmptyState(
              title: 'Pesanan tidak ditemukan',
              message: 'Pesanan mungkin sudah tidak tersedia.',
              actionLabel: 'Kembali',
              onAction: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/orders');
                }
              },
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(order),
                  if (order.latestRejectReason != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _rejection(order.latestRejectReason!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _section('Produk', _items(order)),
                  const SizedBox(height: AppSpacing.lg),
                  _section('Alamat Pengiriman', _address(order)),
                  const SizedBox(height: AppSpacing.lg),
                  _section('Pembayaran', _payment(order)),
                  const SizedBox(height: AppSpacing.lg),
                  _section('Total', _totals(order)),
                  if ((order.status == OrderStatus.shipped ||
                          order.status == OrderStatus.completed) &&
                      order.shipment != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _shipment(order),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _section('Linimasa', _timeline(order)),
                  const SizedBox(height: AppSpacing.lg),
                  _actions(order),
                  const SizedBox(height: AppSpacing.lg),
                  _adminPanel(order),
                ],
              ),
            ),
    );
  }

  Widget _header(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.orderNo,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatDateWib(order.createdAt),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            StatusPill(status: order.status),
            const Spacer(),
            Text(
              formatRupiah(order.total),
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
    );
  }

  Widget _rejection(String reason) {
    return Container(
      key: const Key('reject-reason'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bukti pembayaran ditolak',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reason,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              height: 1.5,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Unggah ulang bukti pembayaran dari halaman pembayaran.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _items(Order order) {
    return Column(
      children: [
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: SizedBox(
                    width: 52,
                    height: 64,
                    child: item.imageAsset.isEmpty
                        ? const ColoredBox(color: AppColors.line)
                        : Image.asset(
                            item.imageAsset,
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
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        item.variantLabel,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${item.qty} × ${formatRupiah(item.unitPrice)}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(item.lineTotal),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _address(Order order) {
    final snapshot = order.addressSnapshot;
    String value(String key) => snapshot[key]?.toString() ?? '';
    final area = [
      value('addressLine'),
      value('district'),
      value('city'),
      value('province'),
      value('postalCode'),
    ].where((part) => part.isNotEmpty).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (value('label').isNotEmpty)
          Text(
            value('label'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.terracotta,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${value('recipientName')} · ${value('recipientPhone')}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          area,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            height: 1.5,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _payment(Order order) {
    final snapshot = order.paymentMethodSnapshot;
    final type = snapshot['type'] == 'ewallet' ? 'E-Wallet' : 'Transfer Bank';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${snapshot['provider'] ?? '-'} · $type',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${snapshot['accountNo'] ?? '-'}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.ink,
          ),
        ),
        Text(
          'a.n. ${snapshot['accountName'] ?? '-'}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _totals(Order order) {
    return Column(
      children: [
        _costRow('Subtotal', formatRupiah(order.subtotal)),
        const SizedBox(height: AppSpacing.sm),
        _costRow(
          'Ongkir',
          order.shippingNote ?? formatRupiah(order.shippingCost),
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
              formatRupiah(order.total),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.terracotta,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _costRow(String label, String value) {
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
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _shipment(Order order) {
    final shipment = order.shipment!;
    return Container(
      key: const Key('detail-shipment'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengiriman',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CopyField(
            label: 'Nomor Resi',
            value: shipment.trackingNo,
            helper: shipment.courier,
          ),
        ],
      ),
    );
  }

  Widget _timeline(Order order) {
    return Column(
      children: [
        for (var index = 0; index < order.statusLogs.length; index++)
          _logEntry(
            order.statusLogs[index],
            last: index == order.statusLogs.length - 1,
          ),
      ],
    );
  }

  Widget _logEntry(StatusLog log, {required bool last}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 1, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.toStatus.label,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDateWib(log.createdAt)} · ${log.actor.label}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  if (log.note != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      log.note!,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(Order order) {
    if (order.status == OrderStatus.awaitingPayment) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RnzButton(
            key: const Key('pay-now'),
            label: 'Bayar Sekarang',
            onPressed: () => context.push('/orders/${order.id}/payment'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            key: const Key('cancel-order'),
            onPressed: _busy ? null : _cancel,
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.shipped) {
      return RnzButton(
        key: const Key('complete-order'),
        label: 'Pesanan Diterima',
        loading: _busy,
        onPressed: _complete,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _adminPanel(Order order) {
    final canReview = order.status == OrderStatus.paymentVerification;
    final canShip = order.status == OrderStatus.processing;
    final canCancel = canReview || canShip;
    final hasActions = canReview || canShip || canCancel;

    return Material(
      color: AppColors.forest.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('admin-panel'),
        title: const Text(
          'Mode Demo — aksi admin',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.forest,
          ),
        ),
        subtitle: const Text(
          'Simulasi tindakan admin tanpa backend.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          if (!hasActions)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Tidak ada aksi admin untuk status ini.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ),
          if (canReview) ...[
            RnzButton(
              key: const Key('admin-approve'),
              label: 'Setujui Pembayaran',
              loading: _busy,
              onPressed: _approve,
            ),
            const SizedBox(height: AppSpacing.md),
            RnzTextField(
              fieldKey: const Key('admin-reject-reason'),
              label: 'Alasan penolakan',
              controller: _rejectReason,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('admin-reject'),
              onPressed: _busy ? null : _reject,
              child: const Text('Tolak Pembayaran'),
            ),
          ],
          if (canShip) ...[
            DropdownButtonFormField<String>(
              key: const Key('admin-courier'),
              initialValue: _courier,
              decoration: const InputDecoration(labelText: 'Ekspedisi'),
              items: [
                for (final courier in AppConstants.couriers)
                  DropdownMenuItem(value: courier, child: Text(courier)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _courier = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            RnzTextField(
              fieldKey: const Key('admin-tracking'),
              label: 'Nomor resi',
              hintText: 'Contoh: JNE1234567890',
              controller: _tracking,
            ),
            const SizedBox(height: AppSpacing.sm),
            RnzButton(
              key: const Key('admin-ship'),
              label: 'Kirim Pesanan',
              loading: _busy,
              onPressed: _ship,
            ),
          ],
          if (canCancel) ...[
            const Divider(height: AppSpacing.xl, color: AppColors.line),
            RnzTextField(
              fieldKey: const Key('admin-cancel-reason'),
              label: 'Alasan pembatalan',
              controller: _cancelReason,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              key: const Key('admin-cancel'),
              onPressed: _busy ? null : _adminCancel,
              child: const Text('Batalkan via Admin'),
            ),
          ],
        ],
      ),
    );
  }
}
