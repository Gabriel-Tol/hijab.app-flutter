import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rnz_store/app.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/screens/recovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RnzApp boots to onboarding on first run', (tester) async {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    final app = RnzApp.create(store);

    await tester.pumpWidget(app);
    expect(find.text('RnZ Store'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Koleksi pilihan'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
  });

  testWidgets('RnzApp navigates to home when onboarding is already seen', (
    tester,
  ) async {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    await store.setOnboardingSeen();
    final app = RnzApp.create(store);

    await tester.pumpWidget(app);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Tenang, anggun, siap menemani harimu.'), findsOneWidget);
  });

  testWidgets('RecoveryScreen resets preferences and invokes callback', (
    tester,
  ) async {
    var recovered = false;
    await tester.pumpWidget(
      RecoveryScreen(onRecovered: () => recovered = true),
    );

    expect(find.text('Data Lokal Rusak'), findsOneWidget);
    expect(find.byKey(const Key('recovery-reset-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recovery-reset-button')));
    await tester.pumpAndSettle();

    expect(recovered, isTrue);
  });

  testWidgets('Home screen renders cleanly at 2.0 text scale', (tester) async {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    await store.setOnboardingSeen();
    final app = RnzApp.create(store);

    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2.0),
          size: Size(360, 640),
        ),
        child: app,
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Tenang, anggun, siap menemani harimu.'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
  });
}
