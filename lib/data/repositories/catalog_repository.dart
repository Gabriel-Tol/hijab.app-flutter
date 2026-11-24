import '../api_client.dart';
import '../local_store.dart';
import '../models/catalog.dart';

class CatalogRepository {
  CatalogRepository(this._store, {ApiClient? apiClient}) : _apiClient = apiClient;

  final LocalStore _store;
  final ApiClient? _apiClient;

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

  /// Fetch categories from API with fallback to local store
  Future<List<Category>> fetchCategories() async {
    final localCategories = categories(activeOnly: false);
    if (_apiClient == null) return localCategories;

    final result = await _apiClient!.fetchCategories();
    if (result.isOk && result.value != null) {
      final categories = result.value!
          .map((raw) => Category.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList();

      // Update local store with fresh data
      await _store.write('categories', result.value!);
      return categories;
    }

    return localCategories;
  }

  Future<List<Category>> allCategories() async {
    if (_apiClient != null) {
      return fetchCategories();
    }
    return categories(activeOnly: false);
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

  /// Fetch all products from API with fallback to local store
  Future<List<Product>> fetchProducts({int page = 1, int perPage = 100}) async {
    final localProducts = _store
        .list('products')
        .map((raw) => Product.fromJson(Map<String, dynamic>.from(raw as Map)))
        .where((p) => p.isActive && p.deletedAt == null)
        .toList();

    if (_apiClient == null) return localProducts;

    final result = await _apiClient!.fetchProducts(page: page, perPage: perPage);
    if (result.isOk && result.value != null) {
      final products = result.value!
          .map((raw) => Product.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList();

      // Update local store with fresh data
      await _store.write('products', result.value!);
      return products.where((p) => p.isActive && p.deletedAt == null).toList();
    }

    return localProducts;
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
