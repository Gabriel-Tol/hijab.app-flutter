import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/local_store.dart';
import '../widgets/rnz_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<({String title, String body, String image})> _pages = [
    (
      title: 'Koleksi pilihan',
      body:
          'Hijab tenun dan pashmina yang dipilih dengan teliti untuk hari-hari Anda.',
      image: 'assets/images/products/rnz_05.jpg',
    ),
    (
      title: 'Stok akurat',
      body:
          'Stok setiap varian selalu diperbarui, jadi Anda tidak menunggu barang yang habis.',
      image: 'assets/images/products/rnz_09.jpg',
    ),
    (
      title: 'Pesanan terlacak',
      body:
          'Ikuti status pesanan dari pembayaran sampai paket tiba di tangan Anda.',
      image: 'assets/images/products/rnz_12.jpg',
    ),
  ];

  Future<void> _finish() async {
    await context.read<LocalStore>().setOnboardingSeen();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Lewati'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppRadius.medium,
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 5,
                            child: Image.asset(
                              page.image,
                              fit: BoxFit.cover,
                              semanticLabel: page.title,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.body,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        width: index == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? AppColors.terracotta
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RnzButton(
                    label: last ? 'Mulai Belanja' : 'Lanjut',
                    onPressed: () {
                      if (last) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
