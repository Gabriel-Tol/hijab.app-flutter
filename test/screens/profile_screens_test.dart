import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/core/app_theme.dart';
import 'package:rnz_store/data/local_store.dart';
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
import 'package:rnz_store/state/catalog_controller.dart';
import 'package:rnz_store/state/order_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late CatalogRepository catalogRepository;
  late ProfileRepository profileRepository;
  late CheckoutRepository checkoutRepository;
  late CatalogController catalog;
  late AuthController auth;
  late CartController cart;
  late OrderController orders;
  late GoRouter router;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

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
    catalog = CatalogController(catalogRepository);
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
  }

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStore>.value(value: store),
          Provider<CatalogRepository>.value(value: catalogRepository),
          Provider<ProfileRepository>.value(value: profileRepository),
          Provider<CheckoutRepository>.value(value: checkoutRepository),
          ChangeNotifierProvider<CatalogController>.value(value: catalog),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<CartController>.value(value: cart),
          ChangeNotifierProvider<OrderController>.value(value: orders),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  testWidgets('profile shows the user name and menu items', (tester) async {
    await loginAsDemo();
    await pumpAt(tester, '/profile');

    expect(find.text('Nadia Putri'), findsOneWidget);
    expect(find.text(SeedData.demoEmail), findsOneWidget);
    expect(find.text('Ubah Profil'), findsOneWidget);
    expect(find.text('Kelola Alamat'), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.text('Hubungi Toko'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.text('Mode Demo'), findsOneWidget);
    expect(find.text('Reset Data Demo'), findsOneWidget);
  });

  testWidgets('change password rejects a wrong current password', (
    tester,
  ) async {
    await loginAsDemo();
    await pumpAt(tester, '/change-password');

    await tester.enterText(
      find.byKey(const Key('password-current')),
      'WrongPass123',
    );
    await tester.enterText(
      find.byKey(const Key('password-new')),
      'NewPass1234',
    );
    await tester.enterText(
      find.byKey(const Key('password-confirm')),
      'NewPass1234',
    );

    await tester.ensureVisible(find.byKey(const Key('password-submit')));
    await tester.tap(find.byKey(const Key('password-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi saat ini tidak sesuai.'), findsOneWidget);
  });

  testWidgets('delete account is blocked while an order is active', (
    tester,
  ) async {
    await loginAsDemo();
    await pumpAt(tester, '/delete-account');

    await tester.enterText(
      find.byKey(const Key('delete-password')),
      SeedData.demoPassword,
    );
    await tester.ensureVisible(find.byKey(const Key('delete-submit')));
    await tester.tap(find.byKey(const Key('delete-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-confirm-dialog')));
    await tester.pumpAndSettle();

    expect(
      find.text('Tidak dapat menghapus akun selama masih ada pesanan aktif.'),
      findsOneWidget,
    );
  });

  testWidgets('privacy screen shows the local-data notice', (tester) async {
    await pumpAt(tester, '/privacy');

    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.textContaining('Penyimpanan Lokal'), findsWidgets);
  });

  testWidgets('logout returns to the public home', (tester) async {
    await loginAsDemo();
    await pumpAt(tester, '/profile');

    await tester.ensureVisible(find.byKey(const Key('profile-logout')));
    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-logout-confirm')));
    await tester.pumpAndSettle();

    expect(auth.isLoggedIn, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });
}
