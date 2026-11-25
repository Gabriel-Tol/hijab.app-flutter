import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/app_snackbar.dart';
import '../../core/formatters.dart';
import '../../data/models/catalog.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/rnz_button.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _gallery = PageController();

  Product? _product;
  String? _categoryName;
  String? _color;
  String? _size;
  int _qty = 1;
  int _image = 0;

  @override
  void initState() {
    super.initState();
    final repository = context.read<CatalogRepository>();
    _product = repository.productById(widget.productId);
    final product = _product;
    if (product != null) {
      for (final category in repository.categories(activeOnly: false)) {
        if (category.id == product.categoryId) _categoryName = category.name;
      }
    }
  }

  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  List<ProductVariant> get _variants =>
      _product?.variants.where((variant) => variant.isActive).toList(
        growable: false,
      ) ??
      const [];

  List<String> get _colors {
    final seen = <String>{};
    return [
      for (final variant in _variants)
        if (seen.add(variant.color)) variant.color,
    ];
  }

  List<String> get _sizes {
    final seen = <String>{};
    return [
      for (final variant in _variants)
        if (variant.size != null &&
            variant.size!.isNotEmpty &&
            seen.add(variant.size!))
          variant.size!,
    ];
  }

  ProductVariant? _variantFor(String color, String? size) {
    for (final variant in _variants) {
      if (variant.color == color && variant.size == size) return variant;
    }
    return null;
  }

  ProductVariant? get _selectedVariant {
    final color = _color;
    if (color == null) return null;
    if (_sizes.isNotEmpty && _size == null) return null;
    return _variantFor(color, _sizes.isEmpty ? null : _size);
  }

  bool _colorAvailable(String color) {
    return _variants.any(
      (variant) => variant.color == color && variant.stock > 0,
    );
  }

  bool _sizeAvailable(String size) {
    final color = _color;
    if (color == null) {
      return _variants.any(
        (variant) => variant.size == size && variant.stock > 0,
      );
    }
    return (_variantFor(color, size)?.stock ?? 0) > 0;
  }

  void _selectColor(String color) {
    setState(() {
      _color = color;
      _qty = 1;
      if (_sizes.isEmpty) {
        _size = null;
        return;
      }
      final current = _size;
      final valid =
          current != null && (_variantFor(color, current)?.stock ?? 0) > 0;
      if (valid) return;
      _size = null;
      for (final size in _sizes) {
        if ((_variantFor(color, size)?.stock ?? 0) > 0) {
          _size = size;
          break;
        }
      }
    });
  }

  void _selectSize(String size) {
    setState(() {
      _size = size;
      _qty = 1;
    });
  }

  Future<void> _add() async {
    final product = _product;
    final variant = _selectedVariant;
    if (product == null || variant == null) return;

    if (!context.read<AuthController>().isLoggedIn) {
      final from = Uri.encodeComponent('/product/${product.id}');
      context.push('/login?from=$from');
      return;
    }

    final result = context.read<CartController>().add(
      variant.id,
      qty: _qty,
    );
    if (!mounted) return;
    final message = result.isOk
        ? '$_qty ${variant.label} ditambahkan ke keranjang.'
        : result.error!.fields[variant.id] ?? result.error!.message;
    showRnzSnackBar(
      context,
      message: message,
      type: result.isOk ? SnackType.success : SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final product = _product;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            key: const Key('product-cart'),
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
      body: product == null
          ? EmptyState(
              title: 'Produk tidak ditemukan',
              message: 'Produk mungkin sudah tidak tersedia.',
              actionLabel: 'Kembali',
              onAction: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                _galleryView(product),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: _details(product),
                ),
              ],
            ),
    );
  }

  Widget _galleryView(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 360,
        color: AppColors.line,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.muted,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 360,
          child: PageView.builder(
            key: const Key('product-gallery'),
            controller: _gallery,
            itemCount: product.images.length,
            onPageChanged: (index) => setState(() => _image = index),
            itemBuilder: (context, index) {
              return ClipRect(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: product.images[index].startsWith('http://') ||
                          product.images[index].startsWith('https://')
                      ? Image.network(
                          product.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          semanticLabel: '${product.name} ${index + 1}',
                          errorBuilder: (context, error, stackTrace) => const ColoredBox(
                            color: AppColors.line,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        )
                      : Image.asset(
                          product.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          semanticLabel: '${product.name} ${index + 1}',
                          errorBuilder: (context, error, stackTrace) => const ColoredBox(
                            color: AppColors.line,
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (product.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(product.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  width: index == _image ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _image
                        ? AppColors.terracotta
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _details(Product product) {
    final variant = _selectedVariant;
    final sizes = _sizes;
    final colors = _colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (_categoryName ?? 'Koleksi').toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.name,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          formatRupiah(product.price),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Stok tersedia: ${product.totalStock}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          product.description,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            height: 1.6,
            color: AppColors.ink,
          ),
        ),
        if (colors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Warna',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final color in colors) _colorChip(color),
            ],
          ),
        ],
        if (sizes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Ukuran',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final size in sizes) _sizeChip(size),
            ],
          ),
        ],
        if (_color == null) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Pilih warna untuk melihat ketersediaan.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
        if (variant != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${variant.label} · stok ${variant.stock}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              QuantityStepper(
                value: _qty,
                min: 1,
                max: variant.stock < 1 ? 1 : variant.stock,
                onChanged: (value) => setState(() => _qty = value),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        RnzButton(
          key: const Key('product-add'),
          label: 'Tambah ke Keranjang',
          onPressed: variant != null && variant.stock > 0 ? _add : null,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _colorChip(String color) {
    final available = _colorAvailable(color);
    return ChoiceChip(
      key: Key('variant-$color'),
      label: Text(available ? color : '$color · Habis'),
      selected: _color == color,
      onSelected: available ? (_) => _selectColor(color) : null,
    );
  }

  Widget _sizeChip(String size) {
    final available = _sizeAvailable(size);
    return ChoiceChip(
      key: Key('size-$size'),
      label: Text(available ? size : '$size · Habis'),
      selected: _size == size,
      onSelected: available ? (_) => _selectSize(size) : null,
    );
  }
}
