import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/address.dart';
import 'package:rnz_store/data/models/order.dart';
import 'package:rnz_store/data/repositories/auth_repository.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/checkout_repository.dart';
import 'package:rnz_store/data/repositories/order_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const AddressDraft _draft = AddressDraft(
  label: 'Rumah',
  recipientName: 'Aisyah',
  recipientPhone: '08111222333',
  province: 'Kalimantan Barat',
  city: 'Pontianak',
  district: 'Pontianak Kota',
  addressLine: 'Jl. Merdeka No. 5',
  postalCode: '78112',
);

void main() {
  final t0 = DateTime(2026, 11, 14, 9);
  late LocalStore store;
  late CatalogRepository catalog;
  late CartRepository cart;
  late ProfileRepository profile;
  late CheckoutRepository checkout;
  late OrderRepository orders;
  late String userId;
  late String addressId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalog = CatalogRepository(store);
    cart = CartRepository(store, catalog);
    profile = ProfileRepository(store);
    checkout = CheckoutRepository(store, cart, catalog);
    orders = OrderRepository(store, cart, profile, checkout);

    final auth = AuthRepository(store);
    final registered = await auth.register(
      name: 'Aisyah',
      email: 'aisyah@example.com',
      phone: '08111222333',
      password: 'Hijab1234',
      address: _draft,
      now: t0,
    );
    userId = registered.value!.id;
    addressId = profile.defaultAddress(userId)!.id;
  });

  test('summary uses the city rate and falls back to admin confirmation', () async {
    cart.add(userId, 'p01-v1', qty: 2);
    final address = profile.defaultAddress(userId)!;

    final summary = checkout.summary(userId: userId, address: address);
    expect(summary.subtotal, 178000);
    expect(summary.shippingCost, 15000);
    expect(summary.shippingNote, isNull);
    expect(summary.total, 193000);
    expect(summary.lines.single.qty, 2);

    final added = await profile.addAddress(
      userId,
      const AddressDraft(
        label: 'Kantor',
        recipientName: 'Aisyah',
        recipientPhone: '08111222333',
        province: 'Jawa Barat',
        city: 'Bekasi',
        district: 'Bekasi Timur',
        addressLine: 'Jl. Ahmad Yani No. 2',
        postalCode: '17111',
      ),
    );
    final fallback = checkout.summary(userId: userId, address: added.value!);
    expect(fallback.shippingCost, 0);
    expect(fallback.shippingNote, 'Ongkir dikonfirmasi admin');

    final methods = checkout.activePaymentMethods();
    expect(methods.map((method) => method.id), ['pm-bca', 'pm-mandiri', 'pm-dana']);
    expect(checkout.paymentMethodById('pm-ovo'), isNull);
  });

  test('createOrder snapshots data, decrements stock, and clears cart', () async {
    cart.add(userId, 'p01-v1', qty: 2);

    final result = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'k1',
      now: t0,
    );

    expect(result.isOk, isTrue);
    final order = result.value!;
    expect(order.orderNo, matches(RegExp(r'^RNZ-\d{6}-\d{4}$')));
    expect(order.status, OrderStatus.awaitingPayment);
    expect(order.subtotal, 178000);
    expect(order.shippingCost, 15000);
    expect(order.total, order.subtotal + order.shippingCost);
    expect(order.payBefore, t0.add(const Duration(hours: 24)));
    expect(order.addressSnapshot['recipientName'], 'Aisyah');
    expect(order.paymentMethodSnapshot['provider'], 'BCA');
    expect(order.items.single.productName, 'Hijab Voal Premium Sage');
    expect(order.items.single.qty, 2);
    expect(order.statusLogs.single.toStatus, OrderStatus.awaitingPayment);

    expect(cart.lines(userId), isEmpty);
    expect(catalog.variantById('p01-v1')!.stock, 10);
    expect(orders.ordersFor(userId).length, 1);
  });

  test('insufficient stock fails atomically and names short lines', () async {
    cart.add(userId, 'p10-v1', qty: 4);

    final products = store
        .list('products')
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final product = products.firstWhere((item) => item['id'] == 'p10');
    final variants = (product['variants'] as List<dynamic>)
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    variants.firstWhere((variant) => variant['id'] == 'p10-v1')['stock'] = 2;
    product['variants'] = variants;
    await store.write('products', products);

    final result = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'short',
      now: t0,
    );

    expect(result.error!.code, 'stock');
    expect(result.error!.fields['p10-v1'], 'Stok tersisa 2');
    expect(catalog.variantById('p10-v1')!.stock, 2);
    expect(cart.lines(userId), isNotEmpty);
    expect(orders.ordersFor(userId), isEmpty);
  });

  test('same idempotency key returns the same order and decrements once', () async {
    cart.add(userId, 'p01-v1');

    final first = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'same',
      now: t0,
    );
    final second = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'same',
      now: t0,
    );

    expect(second.value!.id, first.value!.id);
    expect(catalog.variantById('p01-v1')!.stock, 11);
    expect(orders.ordersFor(userId).length, 1);
  });

  test('order numbers increment per day', () async {
    cart.add(userId, 'p01-v1');
    final first = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'day-1',
      now: t0,
    );
    cart.add(userId, 'p02-v1');
    final second = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'day-2',
      now: t0,
    );
    cart.add(userId, 'p03-v1');
    final nextDay = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'day-3',
      now: t0.add(const Duration(days: 1)),
    );

    expect(first.value!.orderNo, 'RNZ-261114-0001');
    expect(second.value!.orderNo, 'RNZ-261114-0002');
    expect(nextDay.value!.orderNo, 'RNZ-261115-0001');
  });
}
