import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../state/catalog_controller.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/skeleton_grid.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _query;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final catalog = context.read<CatalogController>();
    _query = TextEditingController(text: catalog.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (catalog.products.isEmpty && !catalog.loading) catalog.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      if (!mounted) return;
      context.read<CatalogController>().search(value);
    });
  }

  void _reset() {
    _debounce?.cancel();
    _query.clear();
    setState(() {});
    context.read<CatalogController>().resetFilters();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('search-back'),
                    tooltip: 'Kembali',
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: TextField(
                      key: const Key('search-field'),
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (value) {
                        _debounce?.cancel();
                        context.read<CatalogController>().search(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari hijab, pashmina, gamis...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus kata kunci',
                                onPressed: () {
                                  _query.clear();
                                  _onChanged('');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CategoryChips(
              categories: catalog.categories,
              selectedId: catalog.categoryId,
              onSelected: catalog.selectCategory,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    '${catalog.total} hasil',
                    key: const Key('search-count'),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('search-reset'),
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            Expanded(child: _results(catalog)),
          ],
        ),
      ),
    );
  }

  Widget _results(CatalogController catalog) {
    return RefreshIndicator(
      onRefresh: catalog.refresh,
      child: _content(catalog),
    );
  }

  Widget _content(CatalogController catalog) {
    if (catalog.loading && catalog.products.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        child: const SkeletonGrid(),
      );
    }

    if (catalog.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 340,
            child: EmptyState(
              title: catalog.error == null
                  ? 'Produk tidak ditemukan'
                  : 'Gagal memuat katalog',
              message: catalog.error ??
                  'Coba hapus kata kunci atau pilih kategori lain.',
              actionLabel: 'Coba Lagi',
              onAction: () => catalog.search(_query.text),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) catalog.loadMore();
        return false;
      },
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.55,
        ),
        itemCount: catalog.products.length + (catalog.loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= catalog.products.length) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final product = catalog.products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push('/product/${product.id}'),
          );
        },
      ),
    );
  }
}
