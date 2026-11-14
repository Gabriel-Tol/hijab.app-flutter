import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const userId = 'u-demo';
  late LocalStore store;
  late CatalogRepository catalog;
  late CartRepository cart;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalog = CatalogRepository(store);
    cart = CartRepository(store, catalog);
  });

  test('adding the same variant merges quantities', () {
    expect(cart.add(userId, 'p01-v1', qty: 2).isOk, isTrue);
    expect(cart.add(userId, 'p01-v1').isOk, isTrue);

    final lines = cart.lines(userId);
    expect(lines.single.variant.id, 'p01-v1');
    expect(lines.single.qty, 3);
    expect(cart.itemCount(userId), 3);
    expect(cart.subtotal(userId), 3 * 89000);
  });

  test('adding beyond stock fails with "Stok tersisa N"', () {
    expect(cart.add(userId, 'p10-v1', qty: 4).isOk, isTrue);

    final result = cart.add(userId, 'p10-v1');
    expect(result.isOk, isFalse);
    expect(result.error!.fields['p10-v1'], 'Stok tersisa 4');
    expect(cart.lines(userId).single.qty, 4);

    expect(cart.add(userId, 'p21-v1').isOk, isFalse);
  });

  test('setQty below 1 fails and above stock fails', () {
    expect(cart.add(userId, 'p01-v1', qty: 2).isOk, isTrue);

    final below = cart.setQty(userId, 'p01-v1', 0);
    expect(below.isOk, isFalse);
    expect(below.error!.code, 'validation');

    final above = cart.setQty(userId, 'p01-v1', 13);
    expect(above.isOk, isFalse);
    expect(above.error!.fields['p01-v1'], 'Stok tersisa 12');
    expect(cart.lines(userId).single.qty, 2);

    expect(cart.setQty(userId, 'p01-v1', 5).isOk, isTrue);
    expect(cart.lines(userId).single.qty, 5);
  });

  test('remove and clear update the count and subtotal', () async {
    expect(cart.add(userId, 'p01-v1', qty: 2).isOk, isTrue);
    expect(cart.add(userId, 'p02-v1').isOk, isTrue);
    expect(cart.itemCount(userId), 3);
    expect(cart.subtotal(userId), 2 * 89000 + 75000);

    await cart.remove(userId, 'p01-v1');
    expect(cart.itemCount(userId), 1);
    expect(cart.subtotal(userId), 75000);

    await cart.clear(userId);
    expect(cart.lines(userId), isEmpty);
    expect(cart.itemCount(userId), 0);
    expect(cart.subtotal(userId), 0);
  });

  test('reconcile clamps quantities and removes zero-stock lines', () async {
    await store.write('cart', {
      userId: [
        {'variantId': 'p14-v3', 'qty': 99},
        {'variantId': 'p14-v6', 'qty': 2},
      ],
    });

    final warnings = cart.reconcile(userId);
    final lines = cart.lines(userId);
    expect(lines.single.variant.id, 'p14-v3');
    expect(lines.single.qty, 3);
    expect(warnings.length, 2);
    expect(warnings.any((warning) => warning.contains('Stok')), isTrue);
    expect(store.map('cart')[userId], hasLength(1));
  });
}
