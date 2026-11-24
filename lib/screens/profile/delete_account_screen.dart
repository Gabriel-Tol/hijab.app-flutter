import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/validators.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showRnzConfirm(
      context,
      title: 'Hapus Akun Permanen?',
      message:
          'Tindakan ini tidak dapat dibatalkan. Riwayat pesanan Anda akan '
          'dianonimkan dan sesi Anda akan dihapus.',
      cancelLabel: 'Batal',
      confirmLabel: 'Hapus Akun',
      type: DialogType.danger,
      confirmKey: const Key('delete-confirm-dialog'),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    final result = await context.read<ProfileRepository>().deleteAccount(
      password: _password.text,
    );
    if (!mounted) return;

    if (!result.isOk) {
      setState(() {
        _submitting = false;
        _error = result.error!.message;
      });
      return;
    }

    await auth.logout();
    if (!mounted) return;
    showRnzSnackBar(
      context,
      message: 'Akun Anda telah berhasil dihapus.',
      type: SnackType.success,
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Hapus Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.30),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peringatan Penting',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Akun Anda akan dinonaktifkan secara permanen. '
                        'Semua data pribadi akan dihapus, dan nama pada '
                        'pesanan sebelumnya akan diganti dengan "Pelanggan".\n\n'
                        'Jika Anda memiliki pesanan yang sedang berjalan '
                        '(menunggu pembayaran, diproses, atau dikirim), akun '
                        'tidak dapat dihapus hingga pesanan selesai.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                RnzTextField(
                  fieldKey: const Key('delete-password'),
                  label: 'Kata sandi akun',
                  hintText: 'Masukkan kata sandi untuk konfirmasi',
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      Validators.required(v, 'Kata sandi wajib diisi'),
                ),
                const SizedBox(height: AppSpacing.xl),
                RnzButton(
                  key: const Key('delete-submit'),
                  label: 'Hapus Akun Saya',
                  loading: _submitting,
                  onPressed: _delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
