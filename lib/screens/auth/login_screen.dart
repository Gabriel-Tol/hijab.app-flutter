import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  bool _obscure = true;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final result = await context.read<AuthController>().login(
      email: _email.text,
      password: _password.text,
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

    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final safe = from != null && from.startsWith('/');
    context.go(safe ? from : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
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
                  'RnZ Store',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.terracotta,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Masuk',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Lanjutkan belanja hijab tenun pilihan Anda.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                RnzTextField(
                  fieldKey: const Key('login-email'),
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  errorText: _fieldErrors['email'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('login-password'),
                  label: 'Kata sandi',
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  errorText: _fieldErrors['password'],
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Lupa kata sandi?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RnzButton(
                  key: const Key('login-submit'),
                  label: 'Masuk',
                  loading: _submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Lihat katalog'),
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
