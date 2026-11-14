import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/models/address.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _label = TextEditingController(text: 'Rumah');
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _addressLine = TextEditingController();
  final _postalCode = TextEditingController();

  bool _consent = false;
  bool _submitting = false;
  bool _obscure = true;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirm,
      _label,
      _recipientName,
      _recipientPhone,
      _province,
      _city,
      _district,
      _addressLine,
      _postalCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final result = await context.read<AuthController>().register(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      address: AddressDraft(
        label: _label.text,
        recipientName: _recipientName.text,
        recipientPhone: _recipientPhone.text,
        province: _province.text,
        city: _city.text,
        district: _district.text,
        addressLine: _addressLine.text,
        postalCode: _postalCode.text,
      ),
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

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: const Text('Daftar'),
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
                  'Buat akun',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Satu akun untuk belanja dan melacak pesanan Anda.',
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
                  fieldKey: const Key('register-name'),
                  label: 'Nama lengkap',
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  errorText: _fieldErrors['name'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-email'),
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
                  fieldKey: const Key('register-phone'),
                  label: 'Nomor telepon',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.phone,
                  errorText: _fieldErrors['phone'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-password'),
                  label: 'Kata sandi',
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
                  fieldKey: const Key('register-confirm'),
                  label: 'Konfirmasi kata sandi',
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.confirmPassword(value, _password.text),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Alamat pertama',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Alamat ini menjadi alamat utama dan dapat diubah di Profil.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                RnzTextField(
                  fieldKey: const Key('register-label'),
                  label: 'Label alamat',
                  hintText: 'Rumah, Kantor',
                  controller: _label,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Label alamat wajib diisi'),
                  errorText: _fieldErrors['label'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-recipient-name'),
                  label: 'Nama penerima',
                  controller: _recipientName,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  errorText: _fieldErrors['recipientName'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-recipient-phone'),
                  label: 'Telepon penerima',
                  controller: _recipientPhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  errorText: _fieldErrors['recipientPhone'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-province'),
                  label: 'Provinsi',
                  controller: _province,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Provinsi wajib diisi'),
                  errorText: _fieldErrors['province'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-city'),
                  label: 'Kota',
                  controller: _city,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Kota wajib diisi'),
                  errorText: _fieldErrors['city'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-district'),
                  label: 'Kecamatan',
                  controller: _district,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Kecamatan wajib diisi'),
                  errorText: _fieldErrors['district'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-address-line'),
                  label: 'Alamat lengkap',
                  controller: _addressLine,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator: (value) => Validators.required(
                    value,
                    'Alamat lengkap wajib diisi',
                  ),
                  errorText: _fieldErrors['addressLine'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('register-postal-code'),
                  label: 'Kode pos',
                  controller: _postalCode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: Validators.postalCode,
                  errorText: _fieldErrors['postalCode'],
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  key: const Key('register-consent'),
                  value: _consent,
                  onChanged: (value) =>
                      setState(() => _consent = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Saya setuju dengan Kebijakan Privasi RnZ Store.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                RnzButton(
                  key: const Key('register-submit'),
                  label: 'Daftar',
                  loading: _submitting,
                  onPressed: _consent ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sudah punya akun? Masuk'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
