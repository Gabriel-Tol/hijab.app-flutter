import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:rnz_store/state/cart_controller.dart';
import 'package:rnz_store/state/catalog_controller.dart';
import 'package:rnz_store/widgets/product_card.dart';
import 'package:rnz_store/widgets/rnz_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late CatalogRepository catalogRepository;
  late AuthController auth;
  late CatalogController catalog;
  late CartController cart;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalogRepository = CatalogRepository(store);
    auth = AuthController(AuthRepository(store), ProfileRepository(store));
    catalog = CatalogController(catalogRepository);
    cart = CartController(CartRepository(store, catalogRepository), auth);
    router = buildRouter(auth);
  });

  tearDown(() => router.dispose());

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    bool login = false,
  }) async {
    if (login) {
      final result = await auth.login(
        email: SeedData.demoEmail,
        password: SeedData.demoPassword,
      );
      expect(result.isOk, isTrue);
      await cart.load();
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStore>.value(value: store),
          Provider<CatalogRepository>.value(value: catalogRepository),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<CatalogController>.value(value: catalog),
          ChangeNotifierProvider<CartController>.value(value: cart),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  Finder outerScrollable() {
    return find.byType(Scrollable).first;
  }

  testWidgets('home renders the hero, category chips, and product grid', (
    tester,
  ) async {
    await pumpAt(tester, '/home');

    expect(find.text('Tenang, anggun, siap menemani harimu.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Semua'),
      300,
      scrollable: outerScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Semua'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Hijab Voal Premium Sage'),
      400,
      scrollable: outerScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('home shows Stok Habis badge for an out-of-stock product', (
    tester,
  ) async {
    await pumpAt(tester, '/home');

    await tester.scrollUntilVisible(
      find.text('Stok Habis'),
      500,
      scrollable: outerScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stok Habis'), findsOneWidget);
  });

  testWidgets('search debounces and shows result count', (tester) async {
    await pumpAt(tester, '/search');
    expect(find.text('20 hasil'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-field')), 'pash');
    await tester.pump(const Duration(milliseconds: 399));
    expect(find.text('20 hasil'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('6 hasil'), findsOneWidget);
  });

  testWidgets('empty search shows Produk tidak ditemukan', (tester) async {
    await pumpAt(tester, '/search');

    await tester.enterText(
      find.byKey(const Key('search-field')),
      'tidakadaproduk',
    );
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();

    expect(find.text('Produk tidak ditemukan'), findsOneWidget);
    expect(
      find.text('Coba hapus kata kunci atau pilih kategori lain.'),
      findsOneWidget,
    );
  });

  testWidgets('product detail disables add until a variant is chosen', (
    tester,
  ) async {
    await pumpAt(tester, '/product/p01');

    expect(find.text('Hijab Voal Premium Sage'), findsOneWidget);
    expect(find.text('Rp 89.000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('product-add')),
      400,
      scrollable: outerScrollable(),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<RnzButton>(
      find.byKey(const Key('product-add')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('choosing a variant enables add and increments the cart badge', (
    tester,
  ) async {
    await pumpAt(tester, '/product/p01', login: true);

    await tester.scrollUntilVisible(
      find.byKey(const Key('variant-Sage')),
      300,
      scrollable: outerScrollable(),
    );
    await tester.ensureVisible(find.byKey(const Key('variant-Sage')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('variant-Sage')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('product-add')));
    await tester.pumpAndSettle();

    final button = tester.widget<RnzButton>(
      find.byKey(const Key('product-add')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('product-add')));
    await tester.pumpAndSettle();

    expect(cart.count, 1);
    expect(
      find.descendant(
        of: find.byKey(const Key('product-cart')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('gallery can be zoomed with InteractiveViewer', (tester) async {
    await pumpAt(tester, '/product/p01');

    expect(find.byType(InteractiveViewer), findsWidgets);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer).first,
    );
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 4);
  });
}
