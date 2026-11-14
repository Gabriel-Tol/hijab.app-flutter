import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:rnz_store/state/cart_controller.dart';
import 'package:rnz_store/state/catalog_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(LocalStore, AuthController, CatalogController, CartController)>
_setup({bool loggedIn = false}) async {
  final store = await LocalStore.open();
  await store.seedIfNeeded();
  if (loggedIn) await store.setSessionUserId('u-demo');
  final auth = AuthController(AuthRepository(store), ProfileRepository(store));
  final catalogRepository = CatalogRepository(store);
  return (
    store,
    auth,
    CatalogController(catalogRepository),
    CartController(CartRepository(store, catalogRepository), auth),
  );
}

Widget _app(
  LocalStore store,
  AuthController auth,
  CatalogController catalog,
  CartController cart,
  GoRouter router,
) {
  return MultiProvider(
    providers: [
      Provider<LocalStore>.value(value: store),
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<CatalogController>.value(value: catalog),
      ChangeNotifierProvider<CartController>.value(value: cart),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest opening /cart is redirected to /login', (tester) async {
    final (store, auth, catalog, cart) = await _setup();
    final router = buildRouter(auth);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(store, auth, catalog, cart, router));
    router.go('/cart');
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('logged-in user opening /login is sent home', (tester) async {
    final (store, auth, catalog, cart) = await _setup(loggedIn: true);
    final router = buildRouter(auth);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(store, auth, catalog, cart, router));
    router.go('/login');
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
  });
}
