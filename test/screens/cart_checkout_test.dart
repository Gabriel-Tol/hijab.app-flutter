import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/address.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/checkout_repository.dart';
import 'package:rnz_store/data/repositories/order_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:rnz_store/state/cart_controller.dart';
import 'package:rnz_store/state/order_controller.dart';
import 'package:rnz_store/widgets/rnz_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late CatalogRepository catalogRepository;
  late ProfileRepository profileRepository;
  late CheckoutRepository checkoutRepository;
  late AuthController auth;
  late CartController cart;
  late OrderController orders;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalogRepository = CatalogRepository(store);
    final cartRepository = CartRepository(store, catalogRepository);
    profileRepository = ProfileRepository(store);
    checkoutRepository = CheckoutRepository(
      store,
      cartRepository,
      catalogRepository,
    );
    auth = AuthController(AuthRepository(store), profileRepository);
    cart = CartController(cartRepository, auth);
    orders = OrderController(
      OrderRepository(
        store,
        cartRepository,
        profileRepository,
        checkoutRepository,
      ),
      auth,
      cart,
    );
    router = buildRouter(auth);
  });

  tearDown(() => router.dispose());

  Future<void> loginAsDemo() async {
    final result = await auth.login(
      email: SeedData.demoEmail,
      password: SeedData.demoPassword,
    );
    expect(result.isOk, isTrue);
    await cart.load();
  }

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStore>.value(value: store),
          Provider<CatalogRepository>.value(value: catalogRepository),
          Provider<ProfileRepository>.value(value: profileRepository),
          Provider<CheckoutRepository>.value(value: checkoutRepository),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<CartController>.value(value: cart),
          ChangeNotifierProvider<OrderController>.value(value: orders),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  Future<void> fillAddressForm(
    WidgetTester tester, {
    String label = 'Kantor',
  }) async {
    await tester.enterText(find.byKey(const Key('address-label')), label);
    await tester.enterText(
      find.byKey(const Key('address-recipient-name')),
      'Nadia Putri',
    );
    await tester.enterText(
      find.byKey(const Key('address-recipient-phone')),
      '081234567890',
    );
    await tester.enterText(
      find.byKey(const Key('address-province')),
      'Kalimantan Barat',
    );
    await tester.enterText(find.byKey(const Key('address-city')), 'Pontianak');
    await tester.enterText(
      find.byKey(const Key('address-district')),
      'Pontianak Kota',
    );
    await tester.enterText(
      find.byKey(const Key('address-line')),
      'Jl. Gajahmada No. 12',
    );
    await tester.enterText(
      find.byKey(const Key('address-postal-code')),
      '78111',
    );
  }

  testWidgets('empty cart shows the empty state and no checkout button', (
    tester,
  ) async {
    await loginAsDemo();
    await pumpAt(tester, '/cart');

    expect(find.text('Keranjang Anda masih kosong'), findsOneWidget);
    expect(find.text('Mulai Belanja'), findsOneWidget);
    expect(find.byKey(const Key('cart-checkout')), findsNothing);
  });

  testWidgets('quantity change updates the line and total', (tester) async {
    await loginAsDemo();
    expect(cart.add('p01-v1').isOk, isTrue);
    await pumpAt(tester, '/cart');

    expect(
      tester.widget<Text>(find.byKey(const Key('cart-line-total-p01-v1'))).data,
      'Rp 89.000',
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('cart-line-p01-v1')),
        matching: find.byTooltip('Tambah'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cart.lines.single.qty, 2);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-line-total-p01-v1'))).data,
      'Rp 178.000',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      'Rp 178.000',
    );
  });

  testWidgets('removing a line shows Undo and restores it', (tester) async {
    await loginAsDemo();
    expect(cart.add('p01-v1').isOk, isTrue);
    expect(cart.add('p01-v2').isOk, isTrue);
    await pumpAt(tester, '/cart');

    await tester.tap(find.byKey(const Key('cart-remove-p01-v1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart-line-p01-v1')), findsNothing);
    expect(find.text('Urungkan'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cart-line-p01-v1')), findsOneWidget);
    expect(cart.lines.any((line) => line.variant.id == 'p01-v1'), isTrue);
  });

  testWidgets('checkout blocks when there is no address', (tester) async {
    await loginAsDemo();
    expect(cart.add('p01-v1').isOk, isTrue);
    expect(
      (await profileRepository.deleteAddress('u-demo', 'a1')).isOk,
      isTrue,
    );
    expect(
      (await profileRepository.deleteAddress('u-demo', 'a2')).isOk,
      isTrue,
    );

    await pumpAt(tester, '/checkout');

    expect(
      find.text('Tambahkan alamat pengiriman terlebih dahulu.'),
      findsOneWidget,
    );
    final button = tester.widget<RnzButton>(
      find.byKey(const Key('checkout-submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('checkout shows shipping fallback for an unknown city', (
    tester,
  ) async {
    await loginAsDemo();
    expect(cart.add('p01-v1').isOk, isTrue);
    final address = profileRepository.addressById('u-demo', 'a1')!;
    final updated = await profileRepository.updateAddress(
      'u-demo',
      address.copyWith(city: 'Sintang'),
    );
    expect(updated.isOk, isTrue);

    await pumpAt(tester, '/checkout');

    expect(find.text('Ongkir dikonfirmasi admin'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('checkout-total'))).data,
      'Rp 89.000',
    );
  });

  testWidgets('address form rejects the sixth address', (tester) async {
    await loginAsDemo();
    for (var index = 0; index < 3; index++) {
      final result = await profileRepository.addAddress(
        'u-demo',
        AddressDraft(
          label: 'Alamat ${index + 3}',
          recipientName: 'Nadia Putri',
          recipientPhone: '081234567890',
          province: 'Kalimantan Barat',
          city: 'Pontianak',
          district: 'Pontianak Kota',
          addressLine: 'Jl. Gajahmada No. ${index + 12}',
          postalCode: '78111',
        ),
      );
      expect(result.isOk, isTrue);
    }
    expect(profileRepository.addresses('u-demo').length, 5);

    await pumpAt(tester, '/addresses/new');
    await fillAddressForm(tester);
    await tester.ensureVisible(find.byKey(const Key('address-save')));
    await tester.tap(find.byKey(const Key('address-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Maksimal 5 alamat. Hapus salah satu alamat terlebih dahulu.'),
      findsOneWidget,
    );
  });

  testWidgets('create order navigates to the payment screen', (tester) async {
    await loginAsDemo();
    expect(cart.add('p01-v1').isOk, isTrue);
    await orders.load();
    final before = orders.orders.length;
    await pumpAt(tester, '/checkout');

    final button = tester.widget<RnzButton>(
      find.byKey(const Key('checkout-submit')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('checkout-submit')));
    await tester.pumpAndSettle();

    expect(orders.orders.length, before + 1);
    expect(cart.lines, isEmpty);
    expect(find.text('Pembayaran'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      matches(RegExp(r'^/orders/[^/]+/payment$')),
    );
  });
}
