import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/order.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/checkout_repository.dart';
import 'package:rnz_store/data/repositories/order_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:rnz_store/state/cart_controller.dart';
import 'package:rnz_store/state/catalog_controller.dart';
import 'package:rnz_store/state/order_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late CatalogRepository catalogRepo;
  late CartRepository cartRepo;
  late ProfileRepository profile;
  late OrderRepository orderRepo;
  late AuthController auth;
  late CartController cart;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalogRepo = CatalogRepository(store);
    cartRepo = CartRepository(store, catalogRepo);
    profile = ProfileRepository(store);
    final checkout = CheckoutRepository(store, cartRepo, catalogRepo);
    orderRepo = OrderRepository(store, cartRepo, profile, checkout);
    auth = AuthController(AuthRepository(store), profile);
    cart = CartController(cartRepo, auth);
    await auth.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
    );
  });

  test('AuthController notifies and exposes the logged-in user', () async {
    var notifications = 0;
    auth.addListener(() => notifications++);

    expect(auth.isLoggedIn, isTrue);
    expect(auth.user!.name, 'Nadia Putri');
    expect(auth.defaultAddress, isNotNull);

    await auth.logout();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.user, isNull);
    expect(notifications, 1);

    final result = await auth.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
    );
    expect(result.isOk, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(notifications, 2);
  });

  test('CatalogController loads, searches, and changes category', () async {
    final catalog = CatalogController(catalogRepo);

    await catalog.load();
    expect(catalog.products.length, 20);
    expect(catalog.total, 20);
    expect(catalog.hasMore, isFalse);
    expect(catalog.categories.length, 5);

    await catalog.search('pash');
    expect(catalog.query, 'pash');
    expect(catalog.total, 6);
    expect(
      catalog.products.every((product) => product.name.contains('Pashmina')),
      isTrue,
    );

    await catalog.selectCategory('c2');
    expect(catalog.categoryId, 'c2');
    expect(catalog.total, 5);

    await catalog.resetFilters();
    expect(catalog.query, isEmpty);
    expect(catalog.categoryId, isNull);
    expect(catalog.total, 20);
  });

  test('CartController add updates count and subtotal', () {
    final result = cart.add('p01-v1', qty: 2);
    expect(result.isOk, isTrue);
    expect(cart.count, 2);
    expect(cart.subtotal, 178000);

    cart.add('p01-v1');
    expect(cart.count, 3);
    expect(cart.subtotal, 267000);
  });

  test('CartController load reconciles stock and exposes warnings', () async {
    await store.write('cart', {
      'u-demo': [
        {'variantId': 'p14-v3', 'qty': 99},
      ],
    });

    await cart.load();

    expect(cart.loading, isFalse);
    expect(cart.count, 3);
    expect(cart.lines.single.qty, 3);
    expect(cart.warnings.single, contains('Stok'));
  });

  test('OrderController create clears the cart through CartController', () async {
    final orders = OrderController(orderRepo, auth, cart);
    cart.add('p01-v1');

    final result = await orders.createOrder(
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'controller-1',
    );

    expect(result.isOk, isTrue);
    expect(cart.count, 0);
    expect(cart.lines, isEmpty);
    expect(cartRepo.lines('u-demo'), isEmpty);
    expect(result.value!.total, 104000);
  });

  test('OrderController status filter reloads the filtered list', () async {
    final orders = OrderController(orderRepo, auth, cart);

    await orders.load();
    expect(orders.orders.length, greaterThanOrEqualTo(2));

    await orders.setStatusFilter(OrderStatus.completed);
    expect(orders.statusFilter, OrderStatus.completed);
    expect(orders.orders, isNotEmpty);
    expect(
      orders.orders.every((order) => order.status == OrderStatus.completed),
      isTrue,
    );
  });
}
