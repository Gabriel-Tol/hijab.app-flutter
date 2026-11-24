import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:rnz_store/core/app_theme.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/order.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/checkout_repository.dart';
import 'package:rnz_store/data/repositories/order_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:rnz_store/data/seed_data.dart';
import 'package:rnz_store/routing/app_router.dart';
import 'package:rnz_store/screens/orders/payment_screen.dart';
import 'package:rnz_store/state/auth_controller.dart';
import 'package:rnz_store/state/cart_controller.dart';
import 'package:rnz_store/state/order_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List _jpeg = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a'
  'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIy'
  'MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIA'
  'AhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQA'
  'AAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3'
  'ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWm'
  'p6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEA'
  'AwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSEx'
  'BhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElK'
  'U1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3'
  'uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iii'
  'gD//2Q==',
);

void main() {
  late LocalStore store;
  late CatalogRepository catalogRepository;
  late ProfileRepository profileRepository;
  late CheckoutRepository checkoutRepository;
  late AuthController auth;
  late CartController cart;
  late OrderController orders;
  late GoRouter router;
  var sequence = 0;

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
    sequence = 0;
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

  Future<Order> makeOrder({int qty = 1}) async {
    expect(cart.add('p01-v1', qty: qty).isOk, isTrue);
    final result = await orders.createOrder(
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'test-${sequence++}',
    );
    expect(result.isOk, isTrue);
    return result.value!;
  }

  List<ChangeNotifierProvider<ChangeNotifier>> listenableProviders() {
    return [
      ChangeNotifierProvider<AuthController>.value(value: auth),
      ChangeNotifierProvider<CartController>.value(value: cart),
      ChangeNotifierProvider<OrderController>.value(value: orders),
    ];
  }

  List<Provider<Object>> plainProviders() {
    return [
      Provider<LocalStore>.value(value: store),
      Provider<CatalogRepository>.value(value: catalogRepository),
      Provider<ProfileRepository>.value(value: profileRepository),
      Provider<CheckoutRepository>.value(value: checkoutRepository),
    ];
  }

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [...plainProviders(), ...listenableProviders()],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    router.go(location);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Payment screen runs a 1s timer, so pumpAndSettle never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('orders list filters by status', (tester) async {
    await loginAsDemo();
    await pumpAt(tester, '/orders');

    expect(find.text('Pesanan Saya'), findsOneWidget);
    expect(find.text('RNZ-261102-0001'), findsOneWidget);
    expect(find.text('RNZ-261025-0001'), findsOneWidget);

    final shippedChip = find.byKey(const Key('order-filter-shipped'));
    await tester.ensureVisible(shippedChip);
    await tester.tap(shippedChip);
    await tester.pumpAndSettle();

    expect(find.text('RNZ-261102-0001'), findsOneWidget);
    expect(find.text('RNZ-261025-0001'), findsNothing);

    final awaitingChip = find.byKey(const Key('order-filter-awaitingPayment'));
    await tester.ensureVisible(awaitingChip);
    await tester.tap(awaitingChip);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pesanan'), findsOneWidget);
  });

  testWidgets('detail shows the timeline and rejection reason', (tester) async {
    await loginAsDemo();
    final order = await makeOrder();
    expect(
      (await orders.uploadProof(order.id, _jpeg, 'bukti.jpg')).isOk,
      isTrue,
    );
    expect(
      (await orders.adminReject(order.id, 'Bukti transfer tidak jelas')).isOk,
      isTrue,
    );

    await pumpAt(tester, '/orders/${order.id}');

    expect(find.text('Bukti transfer tidak jelas'), findsWidgets);

    await tester.ensureVisible(
      find.textContaining('Bukti pembayaran diunggah'),
    );
    expect(find.textContaining('Bukti pembayaran diunggah'), findsOneWidget);
    expect(find.textContaining('Pembayaran ditolak'), findsWidgets);
    expect(find.textContaining('Pelanggan'), findsWidgets);
    expect(find.textContaining('Admin'), findsWidgets);
  });

  testWidgets('tracking is hidden before Dikirim and visible after', (
    tester,
  ) async {
    await loginAsDemo();
    final order = await makeOrder();

    await pumpAt(tester, '/orders/${order.id}');
    expect(find.byKey(const Key('detail-shipment')), findsNothing);

    await pumpAt(tester, '/orders/demo-shipped');
    await tester.ensureVisible(find.byKey(const Key('detail-shipment')));
    expect(find.byKey(const Key('detail-shipment')), findsOneWidget);
    expect(find.text('JNE1234567890'), findsOneWidget);
  });

  testWidgets('customer can cancel an awaiting order and stock is restored', (
    tester,
  ) async {
    await loginAsDemo();
    final before = catalogRepository.variantById('p01-v1')!.stock;
    final order = await makeOrder(qty: 2);
    expect(catalogRepository.variantById('p01-v1')!.stock, before - 2);

    await pumpAt(tester, '/orders/${order.id}');
    await tester.ensureVisible(find.byKey(const Key('cancel-order')));
    await tester.tap(find.byKey(const Key('cancel-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-confirm')));
    await tester.pumpAndSettle();

    expect(catalogRepository.variantById('p01-v1')!.stock, before);
    expect(orders.selected!.status, OrderStatus.cancelled);
    expect(find.text('Dibatalkan'), findsWidgets);
  });

  testWidgets('Pesanan Diterima completes a shipped order', (tester) async {
    await loginAsDemo();
    await pumpAt(tester, '/orders/demo-shipped');

    await tester.ensureVisible(find.byKey(const Key('complete-order')));
    await tester.tap(find.byKey(const Key('complete-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('complete-confirm')));
    await tester.pumpAndSettle();

    expect(orders.selected!.status, OrderStatus.completed);
    expect(find.text('Selesai'), findsWidgets);
  });

  testWidgets('payment screen shows the exact total and copy fields', (
    tester,
  ) async {
    await loginAsDemo();
    final order = await makeOrder();
    await pumpAt(tester, '/orders/${order.id}/payment', settle: false);

    expect(find.text('Rp 104.000'), findsWidgets);
    expect(find.byKey(const Key('payment-copy-pm-bca')), findsOneWidget);
    expect(find.byKey(const Key('payment-copy-pm-mandiri')), findsOneWidget);
    expect(find.byKey(const Key('payment-copy-pm-dana')), findsOneWidget);
    expect(find.byKey(const Key('payment-copy-pm-ovo')), findsNothing);
    expect(find.byTooltip('Salin'), findsNWidgets(3));
  });

  testWidgets('proof upload accepts a valid JPEG and moves to verification', (
    tester,
  ) async {
    await loginAsDemo();
    final order = await makeOrder();

    await tester.pumpWidget(
      MultiProvider(
        providers: [...plainProviders(), ...listenableProviders()],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PaymentScreen(orderId: order.id, pickImage: () async => _jpeg),
        ),
      ),
    );
    // Payment screen runs a 1s timer, so bound every pump until upload cancels it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byKey(const Key('payment-pick')));
    await tester.tap(find.byKey(const Key('payment-pick')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('payment-preview')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('payment-upload')));
    await tester.tap(find.byKey(const Key('payment-upload')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bukti terkirim. Menunggu verifikasi.'), findsOneWidget);
    expect(orders.selected!.status, OrderStatus.paymentVerification);
  });

  testWidgets('order detail does not show demo admin panel', (
    tester,
  ) async {
    await loginAsDemo();
    final order = await makeOrder();
    await pumpAt(tester, '/orders/${order.id}');
    expect(find.text('Mode Demo — aksi admin'), findsNothing);
    expect(find.byKey(const Key('admin-panel')), findsNothing);
  });
}
