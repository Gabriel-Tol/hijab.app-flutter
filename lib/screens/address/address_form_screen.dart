import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/models/address.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/rnz_text_field.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _addressLine = TextEditingController();
  final _postalCode = TextEditingController();

  Address? _existing;
  bool _isDefault = false;
  bool _firstAddress = false;
  bool _loaded = false;
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final userId = context.read<AuthController>().user?.id;
    final id = widget.addressId;
    if (userId == null) return;
    if (id == null) {
      _firstAddress = context
          .read<ProfileRepository>()
          .addresses(userId)
          .isEmpty;
      _isDefault = _firstAddress;
      return;
    }

    final address = context.read<ProfileRepository>().addressById(userId, id);
    if (address == null) {
      _error = 'Alamat tidak ditemukan.';
      return;
    }
    _existing = address;
    _isDefault = address.isDefault;
    _label.text = address.label;
    _recipientName.text = address.recipientName;
    _recipientPhone.text = address.recipientPhone;
    _province.text = address.province;
    _city.text = address.city;
    _district.text = address.district;
    _addressLine.text = address.addressLine;
    _postalCode.text = address.postalCode;
  }

  @override
  void dispose() {
    for (final controller in [
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

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userId = context.read<AuthController>().user?.id;
    if (userId == null) {
      setState(() => _error = 'Silakan masuk terlebih dahulu.');
      return;
    }

    setState(() => _submitting = true);
    final repository = context.read<ProfileRepository>();
    final draft = AddressDraft(
      label: _label.text,
      recipientName: _recipientName.text,
      recipientPhone: _recipientPhone.text,
      province: _province.text,
      city: _city.text,
      district: _district.text,
      addressLine: _addressLine.text,
      postalCode: _postalCode.text,
    );

    final existing = _existing;
    if (existing == null) {
      final result = await repository.addAddress(userId, draft);
      if (!mounted) return;
      if (!result.isOk) {
        setState(() {
          _submitting = false;
          _error = result.error!.message;
          _fieldErrors = result.error!.fields;
        });
        return;
      }
      if (_isDefault) {
        await repository.setDefaultAddress(userId, result.value!.id);
      }
      if (!mounted) return;
      context.pop(result.value!.id);
      return;
    }

    final result = await repository.updateAddress(
      userId,
      Address(
        id: existing.id,
        userId: userId,
        label: draft.label,
        recipientName: draft.recipientName,
        recipientPhone: draft.recipientPhone,
        province: draft.province,
        city: draft.city,
        district: draft.district,
        addressLine: draft.addressLine,
        postalCode: draft.postalCode,
        isDefault: _isDefault || existing.isDefault,
      ),
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
    context.pop(result.value!.id);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.addressId != null;
    final defaultLocked = _existing?.isDefault == true || _firstAddress;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text(editing ? 'Ubah Alamat' : 'Tambah Alamat')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.lg),
                ],
                RnzTextField(
                  fieldKey: const Key('address-label'),
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
                  fieldKey: const Key('address-recipient-name'),
                  label: 'Nama penerima',
                  controller: _recipientName,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  errorText: _fieldErrors['recipientName'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-recipient-phone'),
                  label: 'Telepon penerima',
                  controller: _recipientPhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  errorText: _fieldErrors['recipientPhone'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-province'),
                  label: 'Provinsi',
                  controller: _province,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Provinsi wajib diisi'),
                  errorText: _fieldErrors['province'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-city'),
                  label: 'Kota',
                  controller: _city,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Kota wajib diisi'),
                  errorText: _fieldErrors['city'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-district'),
                  label: 'Kecamatan',
                  controller: _district,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Kecamatan wajib diisi'),
                  errorText: _fieldErrors['district'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-line'),
                  label: 'Alamat lengkap',
                  controller: _addressLine,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      Validators.required(value, 'Alamat lengkap wajib diisi'),
                  errorText: _fieldErrors['addressLine'],
                ),
                const SizedBox(height: AppSpacing.md),
                RnzTextField(
                  fieldKey: const Key('address-postal-code'),
                  label: 'Kode pos',
                  controller: _postalCode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  validator: Validators.postalCode,
                  errorText: _fieldErrors['postalCode'],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  key: const Key('address-default'),
                  value: _isDefault,
                  onChanged: defaultLocked
                      ? null
                      : (value) => setState(() => _isDefault = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Jadikan alamat utama',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: defaultLocked
                      ? const Text(
                          'Alamat utama tidak dapat dinonaktifkan.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                RnzButton(
                  key: const Key('address-save'),
                  label: editing ? 'Simpan Perubahan' : 'Simpan Alamat',
                  loading: _submitting,
                  onPressed: _save,
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
