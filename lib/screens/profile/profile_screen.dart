import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../data/models/user.dart';
import '../../state/auth_controller.dart';
import '../../widgets/main_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Anda harus masuk kembali untuk melihat pesanan dan keranjang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('profile-logout-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthController>().logout();
    if (context.mounted) context.go('/home');
  }

  Future<void> _contactStore(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/${AppConstants.storeWhatsApp}');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan kontak.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;

    return MainScaffold(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: AppColors.ivory,
        appBar: AppBar(title: const Text('Profil Saya')),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(user),
                    const SizedBox(height: AppSpacing.xl),
                    _menuCard([
                      _tile(
                        icon: Icons.person_outline,
                        title: 'Ubah Profil',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _tile(
                        icon: Icons.location_on_outlined,
                        title: 'Kelola Alamat',
                        onTap: () => context.push('/addresses'),
                      ),
                      _tile(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                        onTap: () => context.push('/change-password'),
                      ),
                      _tile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Kebijakan Privasi',
                        onTap: () => context.push('/privacy'),
                      ),
                      _tile(
                        icon: Icons.chat_outlined,
                        title: 'Hubungi Toko',
                        onTap: () => _contactStore(context),
                      ),
                      _tile(
                        key: const Key('profile-logout'),
                        icon: Icons.logout,
                        title: 'Keluar',
                        textColor: AppColors.danger,
                        iconColor: AppColors.danger,
                        onTap: () => _logout(context),
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    _dangerCard(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(User user) {
    final initial = user.name.trim().isNotEmpty
        ? user.name.trim()[0].toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.forest,
            child: Text(
              initial,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  user.phone,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(List<Widget> tiles) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: tiles),
    );
  }

  Widget _tile({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = AppColors.ink,
    Color iconColor = AppColors.muted,
  }) {
    return ListTile(
      key: key,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.muted,
      ),
      onTap: onTap,
    );
  }

  Widget _dangerCard(BuildContext context) {
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
          const Text(
            'Zona Berbahaya',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Hapus akun Anda secara permanen. Data pribadi akan dibersihkan.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            key: const Key('delete-account-entry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => context.push('/delete-account'),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
  }
}
