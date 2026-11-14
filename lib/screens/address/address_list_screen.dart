import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models/address.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/auth_controller.dart';
import '../../widgets/rnz_button.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Address> _addresses = const [];
  bool _selecting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _selecting = GoRouterState.of(context).uri.queryParameters['select'] == '1';
    _reload();
  }

  void _reload() {
    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;
    setState(() {
      _addresses = context.read<ProfileRepository>().addresses(userId);
    });
  }

  Future<void> _add() async {
    final id = await context.push<String>('/addresses/new');
    if (!mounted || id == null) return;
    _reload();
    if (_selecting) context.pop(id);
  }

  Future<void> _edit(Address address) async {
    final id = await context.push<String>('/addresses/${address.id}/edit');
    if (!mounted || id == null) return;
    _reload();
  }

  Future<void> _delete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus alamat?'),
        content: Text(
          'Alamat “${address.label}” akan dihapus dari daftar alamat Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('address-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;
    final result = await context.read<ProfileRepository>().deleteAddress(
      userId,
      address.id,
    );
    if (!mounted) return;
    if (!result.isOk) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!.message)));
      return;
    }
    _reload();
  }

  Future<void> _setDefault(Address address) async {
    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;
    final result = await context.read<ProfileRepository>().setDefaultAddress(
      userId,
      address.id,
    );
    if (!mounted) return;
    if (!result.isOk) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!.message)));
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = _addresses.length >= AppConstants.maxAddresses;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Alamat')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (_selecting)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'Pilih alamat pengiriman untuk pesanan ini.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ),
          RnzButton(
            key: const Key('address-add'),
            label: 'Tambah Alamat',
            onPressed: atLimit ? null : _add,
          ),
          if (atLimit)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Maksimal 5 alamat. Hapus salah satu alamat terlebih dahulu.',
                key: Key('address-limit'),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          if (_addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: Column(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 48,
                    color: AppColors.muted,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Belum ada alamat',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tambahkan alamat pengiriman agar Anda dapat checkout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final address in _addresses) _addressCard(address),
        ],
      ),
    );
  }

  Widget _addressCard(Address address) {
    return Container(
      key: Key('address-${address.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: address.isDefault ? AppColors.forest : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: InkWell(
        onTap: _selecting ? () => context.pop(address.id) : null,
        child: Column(
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
                    key: Key('address-default-badge'),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
                const Spacer(),
                if (_selecting)
                  const Icon(Icons.chevron_right, color: AppColors.muted),
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
              '${address.addressLine}, ${address.district}, ${address.city}, '
              '${address.province} ${address.postalCode}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (!address.isDefault)
                  TextButton(
                    key: Key('address-default-${address.id}'),
                    onPressed: () => _setDefault(address),
                    child: const Text('Jadikan Utama'),
                  ),
                TextButton(
                  key: Key('address-edit-${address.id}'),
                  onPressed: () => _edit(address),
                  child: const Text('Ubah'),
                ),
                TextButton(
                  key: Key('address-delete-${address.id}'),
                  onPressed: () => _delete(address),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
