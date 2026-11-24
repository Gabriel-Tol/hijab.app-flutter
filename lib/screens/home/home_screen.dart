import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rnz_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogController>();
      if (catalog.products.isEmpty && !catalog.loading) catalog.load();
    });
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients || _scroll.position.extentAfter > 400) return;
    context.read<CatalogController>().loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final catalog = context.watch<CatalogController>();
    final firstName = auth.user?.name.split(' ').first;

    return MainScaffold(
      currentIndex: 0,
      child: RefreshIndicator(
        onRefresh: catalog.refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.ivory,
              surfaceTintColor: Colors.transparent,
              titleSpacing: AppSpacing.page,
              title: Text(
                firstName == null ? 'RnZ Store' : 'Halo, $firstName',
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              actions: [
                IconButton(
                  key: const Key('home-search'),
                  tooltip: 'Cari',
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  key: const Key('home-cart'),
                  tooltip: 'Keranjang',
                  onPressed: () => context.push('/cart'),
                  icon: Badge.count(
                    count: cart.count,
                    isLabelVisible: cart.count > 0,
                    backgroundColor: AppColors.terracotta,
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            SliverToBoxAdapter(child: _hero(context)),
            SliverToBoxAdapter(
              child: CategoryChips(
                categories: catalog.categories,
                selectedId: catalog.categoryId,
                onSelected: catalog.selectCategory,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                child: SectionHeader(
                  title: 'Pilihan Minggu Ini',
                  actionLabel: 'Cari',
                  onAction: () => context.push('/search'),
                ),
              ),
            ),
            _catalogBody(catalog),
            if (catalog.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.hero,
                fit: BoxFit.cover,
                semanticLabel: 'Koleksi hijab tenun RnZ Store',
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.line),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      AppColors.forest.withValues(alpha: 0.92),
                      AppColors.forest.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Tenang, anggun, siap menemani harimu.',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RnzButton(
                    label: 'Jelajahi Koleksi',
                    expand: false,
                    onPressed: () => context.push('/search'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogBody(CatalogController catalog) {
    if (catalog.loading && catalog.products.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: SkeletonGrid(),
        ),
      );
    }

    if (catalog.products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: EmptyState(
            title: catalog.error == null
                ? 'Belum ada produk'
                : 'Gagal memuat katalog',
            message: catalog.error ?? 'Coba pilih kategori lain.',
            actionLabel: catalog.error == null ? null : 'Coba Lagi',
            onAction: catalog.error == null ? null : catalog.load,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.50,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = catalog.products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push('/product/${product.id}'),
          );
        }, childCount: catalog.products.length),
      ),
    );
  }
}
