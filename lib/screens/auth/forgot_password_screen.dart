import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/app_dialog.dart';
import '../../core/validators.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final result = await context.read<AuthController>().requestResetCode(
      _email.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.isOk) {
      setState(() => _error = result.error!.message);
      return;
    }

    setState(() => _sent = true);
    final code = result.value;
    if (code == null) return;

    final action = await showRnzConfirm(
      context,
      title: 'Kode Verifikasi',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kode reset dibuat untuk akun ini:',
            style: TextStyle(fontFamily: 'Manrope', fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            code,
            key: const Key('demo-reset-code'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Kode verifikasi berlaku selama 30 menit. Masukkan kode ini untuk melanjutkan perubahan kata sandi.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
      cancelLabel: 'Tutup',
      confirmLabel: 'Lanjut Reset',
      type: DialogType.info,
    );
    if (!mounted || !action) return;

    final email = Uri.encodeComponent(Validators.normalizeEmail(_email.text));
    context.push('/reset-password?email=$email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('Lupa Kata Sandi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atur ulang kata sandi',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Masukkan email akun Anda. Kami akan membuat kode reset.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                RnzTextField(
                  fieldKey: const Key('forgot-email'),
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.lg),
                RnzButton(
                  key: const Key('forgot-submit'),
                  label: 'Kirim Kode Reset',
                  loading: _submitting,
                  onPressed: _submit,
                ),
                if (_sent) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Text(
                      'Jika email terdaftar, kode reset telah dibuat.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/reset-password'),
                      child: const Text('Sudah punya kode? Atur ulang sandi'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Kembali ke Masuk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
