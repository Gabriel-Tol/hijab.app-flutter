import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(LocalStore, AuthController)> _setup({bool loggedIn = false}) async {
  final store = await LocalStore.open();
  await store.seedIfNeeded();
  if (loggedIn) await store.setSessionUserId('u-demo');
  return (
    store,
    AuthController(AuthRepository(store), ProfileRepository(store)),
  );
}

Widget _app(LocalStore store, AuthController auth, GoRouter router) {
  return MultiProvider(
    providers: [
      Provider<LocalStore>.value(value: store),
      ChangeNotifierProvider<AuthController>.value(value: auth),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest opening /cart is redirected to /login', (tester) async {
    final (store, auth) = await _setup();
    final router = buildRouter(auth);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(store, auth, router));
    router.go('/cart');
    await tester.pumpAndSettle();

    expect(find.text('Masuk'), findsWidgets);
  });

  testWidgets('logged-in user opening /login is sent home', (tester) async {
    final (store, auth) = await _setup(loggedIn: true);
    final router = buildRouter(auth);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(store, auth, router));
    router.go('/login');
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
  });
}
