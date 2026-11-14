import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late CatalogRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    repo = CatalogRepository(store);
  });

  test('search is case-insensitive and matches partial words', () {
    final result = repo.search(query: 'PASH');
    expect(result.items, isNotEmpty);
    expect(
      result.items.map((product) => product.name),
      everyElement(contains('Pashmina')),
    );
  });

  test('category filter combines with query and counts results', () {
    final result = repo.search(query: 'pash', categoryId: 'c2');
    expect(result.total, 5);
    expect(result.items.length, 5);
    expect(
      result.items.map((product) => product.categoryId),
      everyElement('c2'),
    );
    expect(repo.search(categoryId: 'c2').total, 5);
  });

  test('inactive products are never listed', () {
    final all = repo.search(perPage: 50);
    expect(all.items.length, 20);
    expect(all.items.any((product) => product.id == 'p21'), isFalse);
    expect(repo.productById('p21'), isNull);
    expect(repo.allActive().every((product) => product.isActive), isTrue);
  });

  test('pagination returns perPage items and hasMore', () {
    final first = repo.search(page: 1, perPage: 5);
    expect(first.items.length, 5);
    expect(first.total, 20);
    expect(first.hasMore, isTrue);

    final second = repo.search(page: 2, perPage: 5);
    expect(second.items.length, 5);
    expect(second.items.first.id, isNot(first.items.first.id));

    final last = repo.search(page: 4, perPage: 5);
    expect(last.items.length, 5);
    expect(last.hasMore, isFalse);
  });

  test('productById returns variants and total stock', () {
    final product = repo.productById('p01');
    expect(product, isNotNull);
    expect(product!.variants.length, 3);
    expect(product.totalStock, 20);
    expect(repo.variantById('p01-v1')!.productId, 'p01');
    expect(repo.categories().length, 5);
  });
}
