import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/validators.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool _initialized = false;
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final user = context.read<AuthController>().user;
    if (user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    final result = await context.read<ProfileRepository>().updateProfile(
      name: _name.text,
      phone: _phone.text,
    );
    if (!mounted) return;

    if (!result.isOk) {
      setState(() {
        _submitting = false;
        _error = result.error!.message;
        _fieldErrors = result.error!.fields;
      });
      return;
    }

    auth.refresh();
    setState(() => _submitting = false);
    showRnzSnackBar(
      context,
      message: 'Profil berhasil diperbarui.',
      type: SnackType.success,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Ubah Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                RnzTextField(
                  fieldKey: const Key('edit-name'),
                  label: 'Nama lengkap',
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  errorText: _fieldErrors['name'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('edit-email'),
                  label: 'Alamat email',
                  enabled: false,
                  controller: TextEditingController(text: user?.email ?? ''),
                  hintText: 'Email tidak dapat diubah',
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('edit-phone'),
                  label: 'Nomor telepon',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: Validators.phone,
                  errorText: _fieldErrors['phone'],
                ),
                const SizedBox(height: AppSpacing.xl),
                RnzButton(
                  key: const Key('edit-submit'),
                  label: 'Simpan Perubahan',
                  loading: _submitting,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
