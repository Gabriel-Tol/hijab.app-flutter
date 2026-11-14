import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/master.dart';
import '../../data/models/order.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../state/order_controller.dart';
import '../../widgets/copy_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/status_pill.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.orderId, this.pickImage});

  final String orderId;
  final Future<Uint8List?> Function()? pickImage;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _timer;
  bool _loading = true;
  Uint8List? _bytes;
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PaymentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _timer?.cancel();
      _timer = null;
      _bytes = null;
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = context.read<OrderController>();
    await controller.loadDetail(widget.orderId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (controller.selected?.status == OrderStatus.awaitingPayment) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<Uint8List?> _pickFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.proofMaxDimension.toDouble(),
      maxHeight: AppConstants.proofMaxDimension.toDouble(),
      imageQuality: 70,
    );
    return file?.readAsBytes();
  }

  Future<void> _pick() async {
    final bytes = await (widget.pickImage ?? _pickFromGallery)();
    if (!mounted || bytes == null) return;
    setState(() {
      _bytes = bytes;
      _uploadError = null;
    });
  }

  Future<void> _upload() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    final result = await context.read<OrderController>().uploadProof(
      widget.orderId,
      bytes,
      'bukti.jpg',
    );
    if (!mounted) return;

    if (!result.isOk) {
      setState(() {
        _uploading = false;
        _uploadError = result.error!.message;
      });
      return;
    }

    _timer?.cancel();
    setState(() {
      _uploading = false;
      _bytes = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bukti terkirim. Menunggu verifikasi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    final order = controller.selected?.id == widget.orderId
        ? controller.selected
        : null;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.ivory,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(title: const Text('Pembayaran')),
        body: EmptyState(
          title: 'Pesanan tidak ditemukan',
          message: 'Pesanan mungkin sudah tidak tersedia.',
          actionLabel: 'Kembali',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final methods = context.read<CheckoutRepository>().activePaymentMethods();
    final awaiting = order.status == OrderStatus.awaitingPayment;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
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
            const SizedBox(height: AppSpacing.lg),
            _section('Tujuan Pembayaran', _methods(methods)),
            const SizedBox(height: AppSpacing.lg),
            _section('Bukti Transfer', _uploadCard(order, awaiting)),
          ],
        ),
      ),
    );
  }

  Widget _header(Order order) {
    final remaining = order.payBefore.difference(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Total pembayaran',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.ivory,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatRupiah(order.total),
            key: const Key('payment-total'),
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: AppColors.ivory,
            ),
          ),
          if (order.status == OrderStatus.awaitingPayment) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bayar sebelum ${formatDateWib(order.payBefore)}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: AppColors.ivory,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatCountdown(remaining),
              key: const Key('payment-countdown'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.ivory,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _methods(List<PaymentMethod> methods) {
    return Column(
      children: [
        for (final method in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: CopyField(
              key: Key('payment-copy-${method.id}'),
              label: '${method.provider} · ${method.type.label}',
              value: method.accountNo,
              helper: 'a.n. ${method.accountName}',
            ),
          ),
      ],
    );
  }

  Widget _uploadCard(Order order, bool awaiting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.latestRejectReason != null) ...[
          ErrorBanner(
            message:
                'Bukti sebelumnya ditolak: ${order.latestRejectReason!}. '
                'Silakan unggah ulang.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!awaiting)
          Text(
            order.status == OrderStatus.paymentVerification
                ? 'Bukti pembayaran sedang diverifikasi admin.'
                : 'Status pesanan: ${order.status.label}.',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          )
        else ...[
          if (_bytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Image.memory(
                _bytes!,
                key: const Key('payment-preview'),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.line,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          RnzButton(
            key: const Key('payment-pick'),
            label: _bytes == null ? 'Pilih Bukti Transfer' : 'Ganti Bukti',
            variant: RnzButtonVariant.secondary,
            onPressed: _uploading ? null : _pick,
          ),
          if (_bytes != null) ...[
            const SizedBox(height: AppSpacing.sm),
            RnzButton(
              key: const Key('payment-upload'),
              label: _uploadError == null ? 'Kirim Bukti' : 'Coba Lagi',
              loading: _uploading,
              onPressed: _uploading ? null : _upload,
            ),
          ],
          if (_uploadError != null) ...[
            const SizedBox(height: AppSpacing.md),
            ErrorBanner(message: _uploadError!),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Format JPG, PNG, atau WEBP. Maksimal 5 MB.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ],
      ],
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
}
