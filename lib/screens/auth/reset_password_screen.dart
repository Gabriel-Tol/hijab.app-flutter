import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _prefilled = false;
  bool _submitting = false;
  bool _obscure = true;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final email = GoRouterState.of(context).uri.queryParameters['email'];
    if (email != null) _email.text = email;
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _codeValidator(String? value) {
    final required = Validators.required(value, 'Kode reset wajib diisi');
    if (required != null) return required;
    return RegExp(r'^\d{6}$').hasMatch(value!.trim())
        ? null
        : 'Kode harus 6 digit';
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    final result = await auth.resetPassword(
      email: _email.text,
      code: _code.text.trim(),
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.isOk) {
      setState(() {
        _error = result.error!.message;
        _fieldErrors = result.error!.fields;
      });
      return;
    }

    auth.refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kata sandi berhasil diubah.')),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('Atur Ulang Kata Sandi'),
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
                  'Buat kata sandi baru',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Masukkan kode reset yang Anda terima, lalu pilih kata sandi baru.',
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
                  fieldKey: const Key('reset-email'),
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('reset-code'),
                  label: 'Kode reset',
                  hintText: '6 digit',
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _codeValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('reset-password'),
                  label: 'Kata sandi baru',
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  errorText: _fieldErrors['password'],
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('reset-confirm'),
                  label: 'Konfirmasi kata sandi baru',
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                ),
                const SizedBox(height: AppSpacing.lg),
                RnzButton(
                  key: const Key('reset-submit'),
                  label: 'Simpan Kata Sandi',
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
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
