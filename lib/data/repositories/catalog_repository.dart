import '../local_store.dart';
import '../models/catalog.dart';

class CatalogRepository {
  CatalogRepository(this._store);

  final LocalStore _store;

  List<Category> categories({bool activeOnly = true}) {
    final items = _store
        .list('categories')
        .map((raw) => Category.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
    if (!activeOnly) return items;
    return items
        .where((category) => category.isActive)
        .toList(growable: false);
  }

  List<Product> allActive() {
    final activeCategoryIds = categories()
        .map((category) => category.id)
        .toSet();
    return _products()
        .where(
          (product) =>
              product.isActive &&
              product.deletedAt == null &&
              activeCategoryIds.contains(product.categoryId),
        )
        .toList(growable: false);
  }

  PagedProducts search({
    String query = '',
    String? categoryId,
    int page = 1,
    int perPage = 20,
  }) {
    final normalized = query.trim().toLowerCase();
    final matches = allActive()
        .where((product) {
          if (categoryId != null && product.categoryId != categoryId) {
            return false;
          }
          return normalized.isEmpty ||
              product.name.toLowerCase().contains(normalized);
        })
        .toList()
      ..sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : a.name.compareTo(b.name);
      });

    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;
    final total = matches.length;
    final start = (safePage - 1) * safePerPage;
    final end = start + safePerPage < total ? start + safePerPage : total;
    final items = start >= total
        ? const <Product>[]
        : matches.sublist(start, end);

    return PagedProducts(
      items: items,
      total: total,
      page: safePage,
      perPage: safePerPage,
    );
  }

  Product? productById(String id) {
    for (final product in allActive()) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductVariant? variantById(String id) {
    for (final product in allActive()) {
      for (final variant in product.variants) {
        if (variant.id == id && variant.isActive) return variant;
      }
    }
    return null;
  }

  List<Product> _products() {
    return _store
        .list('products')
        .map((raw) => Product.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }
}
