import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late AuthController auth;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    auth = AuthController(AuthRepository(store), ProfileRepository(store));
    router = buildRouter(auth);
  });

  tearDown(() => router.dispose());

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStore>.value(value: store),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String key, String value) {
    return tester.enterText(find.byKey(Key(key)), value);
  }

  testWidgets('login shows field errors for empty submit', (tester) async {
    await pumpAt(tester, '/login');

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
  });

  testWidgets('login with demo account navigates home', (tester) async {
    await pumpAt(tester, '/login');

    await fill(tester, 'login-email', SeedData.demoEmail);
    await fill(tester, 'login-password', SeedData.demoPassword);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
  });

  testWidgets('login from /cart returns to cart after success', (
    tester,
  ) async {
    await pumpAt(tester, '/cart');

    await fill(tester, 'login-email', SeedData.demoEmail);
    await fill(tester, 'login-password', SeedData.demoPassword);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Keranjang'), findsWidgets);
  });

  testWidgets('register shows duplicate email message', (tester) async {
    await pumpAt(tester, '/register');

    await fill(tester, 'register-name', 'Aisyah');
    await fill(tester, 'register-email', SeedData.demoEmail);
    await fill(tester, 'register-phone', '081199998888');
    await fill(tester, 'register-password', 'Hijab1234');
    await fill(tester, 'register-confirm', 'Hijab1234');
    await fill(tester, 'register-label', 'Rumah');
    await fill(tester, 'register-recipient-name', 'Aisyah');
    await fill(tester, 'register-recipient-phone', '081199998888');
    await fill(tester, 'register-province', 'Kalimantan Barat');
    await fill(tester, 'register-city', 'Pontianak');
    await fill(tester, 'register-district', 'Pontianak Kota');
    await fill(tester, 'register-address-line', 'Jl. Merdeka No. 5');
    await fill(tester, 'register-postal-code', '78112');

    await tester.ensureVisible(find.byKey(const Key('register-consent')));
    await tester.tap(find.byKey(const Key('register-consent')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email sudah terdaftar'), findsOneWidget);
    expect(find.text('Email sudah terdaftar.'), findsOneWidget);
  });

  testWidgets('forgot password shows demo code dialog and reset works', (
    tester,
  ) async {
    await pumpAt(tester, '/forgot-password');

    await fill(tester, 'forgot-email', SeedData.demoEmail);
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Jika email terdaftar, kode reset telah dibuat.'),
      findsOneWidget,
    );
    expect(find.text('Mode Demo'), findsOneWidget);

    final code = tester
        .widget<Text>(find.byKey(const Key('demo-reset-code')))
        .data!;
    expect(code, matches(RegExp(r'^\d{6}$')));

    await tester.tap(find.text('Lanjut Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Atur Ulang Kata Sandi'), findsWidgets);

    await fill(tester, 'reset-code', code);
    await fill(tester, 'reset-password', 'Hijab5678');
    await fill(tester, 'reset-confirm', 'Hijab5678');
    await tester.ensureVisible(find.byKey(const Key('reset-submit')));
    await tester.tap(find.byKey(const Key('reset-submit')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi berhasil diubah.'), findsOneWidget);

    await fill(tester, 'login-email', SeedData.demoEmail);
    await fill(tester, 'login-password', 'Hijab5678');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsWidgets);
  });
}
