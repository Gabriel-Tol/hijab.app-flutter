import 'package:flutter/material.dart';

import '../../core/constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: const Text('Kebijakan Privasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kebijakan Privasi & Data',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Terakhir diperbarui: 14 November 2026',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _section(
              title: '1. Penyimpanan Lokal (Local-Only)',
              body:
                  'Aplikasi RnZ Store ini beroperasi sepenuhnya secara luring '
                  'menggunakan penyimpanan lokal perangkat (SharedPreferences) '
                  'tanpa peladen backend atau basis data eksternal. Semua data '
                  'akun, alamat, pesanan, dan bukti transfer tersimpan hanya pada '
                  'perangkat Anda.',
            ),
            _section(
              title: '2. Data yang Disimpan',
              body:
                  'Data yang dikumpulkan mencakup:\n'
                  '• Nama lengkap, alamat email, dan nomor telepon.\n'
                  '• Kata sandi yang diamankan menggunakan salt acak 16-byte dan '
                  'hashing kriptografi SHA-256.\n'
                  '• Buku alamat pengiriman (maksimal 5 alamat per akun).\n'
                  '• Riwayat transaksi pesanan dan foto bukti transfer yang '
                  'diunggah dalam format Base64 terkompresi.',
            ),
            _section(
              title: '3. Penghapusan dan Privasi Akun',
              body:
                  'Anda memiliki kendali penuh atas data Anda. Pengguna dapat '
                  'meminta penghapusan akun kapan saja melalui menu Pengaturan. '
                  'Saat akun dihapus, identitas pada pesanan lampau akan '
                  'dianonimkan dan seluruh sesi Anda akan dibersihkan.',
            ),
            _section(
              title: '4. Batasan Mode Demo',
              body:
                  'Aplikasi ini merupakan simulasi tugas perkuliahan / portofolio. '
                  'Fitur admin seperti verifikasi pembayaran dan pengiriman resi '
                  'disediakan secara lokal untuk mendemonstrasikan siklus hidup '
                  'pesanan tanpa melibatkan transaksi uang riil.',
            ),
            _section(
              title: '5. Kontak Pengembang',
              body:
                  'Jika Anda memiliki pertanyaan mengenai penggunaan atau '
                  'keamanan aplikasi ini, hubungi tim RnZ Store melalui WhatsApp '
                  'resmi toko di nomor +62 812-3456-7890.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
