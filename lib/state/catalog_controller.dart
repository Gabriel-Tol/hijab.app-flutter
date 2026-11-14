import 'package:flutter/foundation.dart' hide Category;

import '../core/constants.dart';
import '../data/models/catalog.dart';
import '../data/repositories/catalog_repository.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._catalog);

  final CatalogRepository _catalog;

  List<Category> categories = const [];
  List<Product> products = const [];
  bool loading = false;
  bool loadingMore = false;
  String? error;
  bool hasMore = false;
  int total = 0;
  String query = '';
  String? categoryId;

  int _page = 1;

  Future<void> load() => _fetch(page: 1, replace: true);

  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadMore() {
    if (loading || loadingMore || !hasMore) return Future.value();
    return _fetch(page: _page + 1, replace: false);
  }

  Future<void> search(String value) {
    query = value;
    return _fetch(page: 1, replace: true);
  }

  Future<void> selectCategory(String? id) {
    categoryId = id;
    return _fetch(page: 1, replace: true);
  }

  Future<void> resetFilters() {
    query = '';
    categoryId = null;
    return _fetch(page: 1, replace: true);
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    if (replace) {
      loading = true;
    } else {
      loadingMore = true;
    }
    error = null;
    notifyListeners();

    try {
      final result = _catalog.search(
        query: query,
        categoryId: categoryId,
        page: page,
        perPage: AppConstants.productsPerPage,
      );
      products = replace ? result.items : [...products, ...result.items];
      _page = result.page;
      total = result.total;
      hasMore = result.hasMore;
      categories = _catalog.categories();
    } catch (_) {
      error = 'Gagal memuat katalog.';
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }
}
