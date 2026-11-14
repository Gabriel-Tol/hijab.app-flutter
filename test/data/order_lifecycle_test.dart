import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/core/constants.dart';
import 'package:rnz_store/core/result.dart';
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

Uint8List _jpeg() {
  return Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
  ]);
}

void main() {
  final t0 = DateTime(2026, 11, 14, 9);
  late LocalStore store;
  late CatalogRepository catalog;
  late CartRepository cart;
  late OrderRepository orders;
  late String userId;
  late String addressId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
    await store.seedIfNeeded();
    catalog = CatalogRepository(store);
    cart = CartRepository(store, catalog);
    final profile = ProfileRepository(store);
    final checkout = CheckoutRepository(store, cart, catalog);
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

  Future<Order> createOrder({
    int qty = 1,
    String key = 'k1',
    DateTime? now,
  }) async {
    cart.add(userId, 'p01-v1', qty: qty);
    final result = await orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: 'pm-bca',
      idempotencyKey: key,
      now: now ?? t0,
    );
    expect(result.isOk, isTrue);
    return result.value!;
  }

  Future<AppResult<void>> upload(String orderId, {DateTime? now}) {
    return orders.uploadProof(
      orderId: orderId,
      userId: userId,
      bytes: _jpeg(),
      fileName: 'bukti.jpg',
      now: now ?? t0.add(const Duration(hours: 1)),
    );
  }

  test('uploading a JPEG moves the order to verification', () async {
    final order = await createOrder(qty: 2);

    expect((await upload(order.id)).isOk, isTrue);

    final stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.paymentVerification);
    expect(stored.proofs.single.status, PaymentProofStatus.pending);
    expect(
      stored.proofs.single.storageKey,
      startsWith('proof.${order.id}.'),
    );
    expect(
      orders.proofDataUrl(stored.proofs.single),
      startsWith('data:image/jpeg;base64,'),
    );
    expect(stored.statusLogs.length, 2);
    expect(stored.statusLogs.last.actor, ActorType.customer);

    final again = await upload(order.id);
    expect(again.error!.code, 'invalid_transition');
  });

  test('non-image bytes and files over 5 MB are rejected', () async {
    final order = await createOrder();

    final wrongType = await orders.uploadProof(
      orderId: order.id,
      userId: userId,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      fileName: 'catatan.txt',
      now: t0.add(const Duration(hours: 1)),
    );
    expect(wrongType.error!.code, 'invalid_type');
    expect(
      orders.orderById(order.id, userId)!.status,
      OrderStatus.awaitingPayment,
    );

    final huge = await orders.uploadProof(
      orderId: order.id,
      userId: userId,
      bytes: Uint8List(AppConstants.maxProofBytes + 1),
      fileName: 'besar.jpg',
      now: t0.add(const Duration(hours: 1)),
    );
    expect(huge.error!.code, 'file_too_large');
    expect(
      orders.orderById(order.id, userId)!.status,
      OrderStatus.awaitingPayment,
    );
  });

  test('admin rejection requires a reason and returns to awaiting payment', () async {
    final order = await createOrder();
    await upload(order.id);

    final empty = await orders.adminRejectPayment(
      orderId: order.id,
      reason: '   ',
      now: t0.add(const Duration(hours: 2)),
    );
    expect(empty.error!.code, 'validation');
    expect(empty.error!.fields['reason'], isNotEmpty);

    final rejected = await orders.adminRejectPayment(
      orderId: order.id,
      reason: 'Bukti buram',
      now: t0.add(const Duration(hours: 2)),
    );
    expect(rejected.isOk, isTrue);

    var stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.awaitingPayment);
    expect(stored.latestRejectReason, 'Bukti buram');
    expect(stored.payBefore, order.payBefore);
    expect(stored.proofs.single.status, PaymentProofStatus.rejected);
    expect(stored.proofs.single.rejectReason, 'Bukti buram');
    expect(stored.statusLogs.last.actor, ActorType.admin);

    expect((await upload(order.id)).isOk, isTrue);
    stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.paymentVerification);
    expect(stored.latestRejectReason, isNull);
    expect(stored.proofs.length, 2);
  });

  test('admin approval then shipping exposes tracking', () async {
    final order = await createOrder();
    await upload(order.id);

    final approved = await orders.adminApprovePayment(
      orderId: order.id,
      now: t0.add(const Duration(hours: 2)),
    );
    expect(approved.isOk, isTrue);

    var stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.processing);
    expect(stored.proofs.single.status, PaymentProofStatus.approved);
    expect(stored.proofs.single.reviewedAt, t0.add(const Duration(hours: 2)));

    final badCourier = await orders.adminShip(
      orderId: order.id,
      courier: 'Kurir Fiktif',
      trackingNo: 'JNE12345',
      now: t0.add(const Duration(hours: 3)),
    );
    expect(badCourier.error!.fields['courier'], isNotEmpty);

    final badTracking = await orders.adminShip(
      orderId: order.id,
      courier: 'JNE',
      trackingNo: 'ab',
      now: t0.add(const Duration(hours: 3)),
    );
    expect(badTracking.error!.fields['trackingNo'], isNotEmpty);

    final shipped = await orders.adminShip(
      orderId: order.id,
      courier: 'JNE',
      trackingNo: 'JNE12345',
      now: t0.add(const Duration(hours: 3)),
    );
    expect(shipped.isOk, isTrue);

    stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.shipped);
    expect(stored.shipment!.courier, 'JNE');
    expect(stored.shipment!.trackingNo, 'JNE12345');
    expect(stored.shipment!.shippedAt, t0.add(const Duration(hours: 3)));
    expect(stored.statusLogs.last.actor, ActorType.admin);
  });

  test('customer cancel restores stock exactly once and is final', () async {
    final order = await createOrder(qty: 2);
    expect(catalog.variantById('p01-v1')!.stock, 10);

    final cancelled = await orders.cancelByCustomer(
      orderId: order.id,
      userId: userId,
      now: t0.add(const Duration(hours: 1)),
    );
    expect(cancelled.isOk, isTrue);

    var stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.cancelled);
    expect(catalog.variantById('p01-v1')!.stock, 12);
    expect(stored.statusLogs.last.actor, ActorType.customer);

    final again = await orders.cancelByCustomer(
      orderId: order.id,
      userId: userId,
      now: t0.add(const Duration(hours: 2)),
    );
    expect(again.error!.code, 'invalid_transition');
    stored = orders.orderById(order.id, userId)!;
    expect(catalog.variantById('p01-v1')!.stock, 12);
    expect(stored.statusLogs.length, 2);
  });

  test('admin cancel requires a reason and restores stock', () async {
    final order = await createOrder(qty: 1);
    await upload(order.id);
    await orders.adminApprovePayment(
      orderId: order.id,
      now: t0.add(const Duration(hours: 2)),
    );
    expect(catalog.variantById('p01-v1')!.stock, 11);

    final empty = await orders.adminCancel(
      orderId: order.id,
      reason: ' ',
      now: t0.add(const Duration(hours: 3)),
    );
    expect(empty.error!.fields['reason'], isNotEmpty);
    expect(catalog.variantById('p01-v1')!.stock, 11);

    final cancelled = await orders.adminCancel(
      orderId: order.id,
      reason: 'Stok habis',
      now: t0.add(const Duration(hours: 3)),
    );
    expect(cancelled.isOk, isTrue);
    final stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.cancelled);
    expect(stored.statusLogs.last.note, contains('Stok habis'));
    expect(catalog.variantById('p01-v1')!.stock, 12);
  });

  test('invalid transitions are rejected', () async {
    final order = await createOrder();

    final complete = await orders.completeByCustomer(
      orderId: order.id,
      userId: userId,
      now: t0.add(const Duration(hours: 1)),
    );
    expect(complete.error!.code, 'invalid_transition');

    final approve = await orders.adminApprovePayment(
      orderId: order.id,
      now: t0.add(const Duration(hours: 1)),
    );
    expect(approve.error!.code, 'invalid_transition');

    final ship = await orders.adminShip(
      orderId: order.id,
      courier: 'JNE',
      trackingNo: 'JNE12345',
      now: t0.add(const Duration(hours: 1)),
    );
    expect(ship.error!.code, 'invalid_transition');

    final adminCancel = await orders.adminCancel(
      orderId: order.id,
      reason: 'Batal',
      now: t0.add(const Duration(hours: 1)),
    );
    expect(adminCancel.error!.code, 'invalid_transition');

    final stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.awaitingPayment);
    expect(stored.statusLogs.length, 1);
  });

  test('auto-cancel happens after payBefore and is idempotent', () async {
    final order = await createOrder(qty: 2);
    expect(catalog.variantById('p01-v1')!.stock, 10);

    await orders.applyTimeBasedTransitions(
      now: t0.add(const Duration(hours: 1)),
    );
    expect(
      orders.orderById(order.id, userId)!.status,
      OrderStatus.awaitingPayment,
    );

    await orders.applyTimeBasedTransitions(
      now: order.payBefore.add(const Duration(minutes: 1)),
    );
    var stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.cancelled);
    expect(stored.statusLogs.last.actor, ActorType.system);
    expect(stored.statusLogs.last.note, 'Kedaluwarsa');
    expect(catalog.variantById('p01-v1')!.stock, 12);

    await orders.applyTimeBasedTransitions(
      now: order.payBefore.add(const Duration(hours: 1)),
    );
    stored = orders.orderById(order.id, userId)!;
    expect(catalog.variantById('p01-v1')!.stock, 12);
    expect(stored.statusLogs.length, 2);
  });

  test('auto-complete happens 7 days after shipping', () async {
    final order = await createOrder();
    await upload(order.id);
    await orders.adminApprovePayment(
      orderId: order.id,
      now: t0.add(const Duration(hours: 2)),
    );
    final shippedAt = t0.add(const Duration(hours: 3));
    await orders.adminShip(
      orderId: order.id,
      courier: 'JNE',
      trackingNo: 'JNE12345',
      now: shippedAt,
    );

    await orders.applyTimeBasedTransitions(
      now: shippedAt.add(const Duration(days: 6)),
    );
    expect(orders.orderById(order.id, userId)!.status, OrderStatus.shipped);

    await orders.applyTimeBasedTransitions(
      now: shippedAt.add(const Duration(days: 7, minutes: 1)),
    );
    var stored = orders.orderById(order.id, userId)!;
    expect(stored.status, OrderStatus.completed);
    expect(stored.completedAt, shippedAt.add(const Duration(days: 7)));
    expect(stored.statusLogs.last.actor, ActorType.system);
    expect(stored.statusLogs.length, 5);

    await orders.applyTimeBasedTransitions(
      now: shippedAt.add(const Duration(days: 8)),
    );
    stored = orders.orderById(order.id, userId)!;
    expect(stored.statusLogs.length, 5);
  });
}
