import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rnz_store/data/api_client.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:rnz_store/data/models/order.dart';
import 'package:rnz_store/data/repositories/cart_repository.dart';
import 'package:rnz_store/data/repositories/catalog_repository.dart';
import 'package:rnz_store/data/repositories/checkout_repository.dart';
import 'package:rnz_store/data/repositories/order_repository.dart';
import 'package:rnz_store/data/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<
      ({
        LocalStore store,
        CartRepository cart,
        ProfileRepository profile,
        CheckoutRepository checkout,
        CatalogRepository catalog,
      })> createFixtures() async {
    final store = await LocalStore.open();
    await store.seedIfNeeded();
    final catalog = CatalogRepository(store);
    final cart = CartRepository(store, catalog);
    final profile = ProfileRepository(store);
    final checkout = CheckoutRepository(store, cart, catalog);
    return (
      store: store,
      cart: cart,
      profile: profile,
      checkout: checkout,
      catalog: catalog,
    );
  }

  test('OrderRepository calls ApiClient checkout and applies backend order_no',
      () async {
    final f = await createFixtures();
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'test_token', 'user': {'id': 2}}
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/orders/checkout')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 99,
              'order_no': 'RNZ-261124-9999',
              'status': 'awaiting_payment',
              'total': 84000,
            }
          }),
          201,
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiClient = ApiClient(
      client: mock,
      store: f.store,
      baseUrl: 'http://test.local',
    );
    final orderRepo = OrderRepository(
      f.store,
      f.cart,
      f.profile,
      f.checkout,
      apiClient: apiClient,
    );

    await f.cart.add('u-demo', 'p01-v1', qty: 1);
    final result = await orderRepo.createOrder(
      userId: 'u-demo',
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'test-idem-99',
    );

    expect(result.isOk, isTrue);
    expect(result.value!.orderNo, equals('RNZ-261124-9999'));
  });

  test(
      'OrderRepository falls back gracefully to local order when ApiClient fails',
      () async {
    final f = await createFixtures();
    final mock = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    final apiClient = ApiClient(
      client: mock,
      store: f.store,
      baseUrl: 'http://test.local',
    );
    final orderRepo = OrderRepository(
      f.store,
      f.cart,
      f.profile,
      f.checkout,
      apiClient: apiClient,
    );

    await f.cart.add('u-demo', 'p01-v1', qty: 1);
    final result = await orderRepo.createOrder(
      userId: 'u-demo',
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'test-idem-fallback',
    );

    expect(result.isOk, isTrue);
    expect(result.value!.orderNo, startsWith('RNZ-'));
  });

  test(
      'OrderRepository uploadProof calls ApiClient when order has backend id',
      () async {
    final f = await createFixtures();
    var proofUploaded = false;
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'test_token', 'user': {'id': 2}}
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/orders/checkout')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 77,
              'order_no': 'RNZ-261124-0077',
              'status': 'awaiting_payment',
              'total': 84000,
            }
          }),
          201,
        );
      }
      if (request.url.path.endsWith('/orders/77/proof')) {
        proofUploaded = true;
        return http.Response(
          jsonEncode({'success': true, 'message': 'Uploaded'}),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiClient = ApiClient(
      client: mock,
      store: f.store,
      baseUrl: 'http://test.local',
    );
    final orderRepo = OrderRepository(
      f.store,
      f.cart,
      f.profile,
      f.checkout,
      apiClient: apiClient,
    );

    await f.cart.add('u-demo', 'p01-v1', qty: 1);
    final createRes = await orderRepo.createOrder(
      userId: 'u-demo',
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'test-idem-upload',
    );

    expect(createRes.isOk, isTrue);
    final order = createRes.value!;

    final uploadRes = await orderRepo.uploadProof(
      orderId: order.id,
      userId: 'u-demo',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00, 0x01]),
      fileName: 'sample.jpg',
    );

    expect(uploadRes.isOk, isTrue);
    expect(proofUploaded, isTrue);
  });

  test(
      'OrderRepository syncOrders updates order status and shipment from backend',
      () async {
    final f = await createFixtures();
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'test_token', 'user': {'id': 2}}
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/orders/checkout')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 99,
              'order_no': 'RNZ-261124-9999',
              'status': 'awaiting_payment',
              'total': 84000,
            }
          }),
          201,
        );
      }
      if (request.url.path.endsWith('/orders')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 99,
                'order_no': 'RNZ-261124-9999',
                'status': 'shipped',
                'shipment': {
                  'courier': 'JNE',
                  'tracking_no': 'JNE-E2E-12345',
                  'shipped_at': '2026-11-24T05:04:14Z',
                }
              }
            ]
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final apiClient = ApiClient(
      client: mock,
      store: f.store,
      baseUrl: 'http://test.local',
    );
    final orderRepo = OrderRepository(
      f.store,
      f.cart,
      f.profile,
      f.checkout,
      apiClient: apiClient,
    );

    await f.cart.add('u-demo', 'p01-v1', qty: 1);
    final createResult = await orderRepo.createOrder(
      userId: 'u-demo',
      addressId: 'a1',
      paymentMethodId: 'pm-bca',
      idempotencyKey: 'test-idem-sync',
    );
    expect(createResult.isOk, isTrue);

    await orderRepo.syncOrders();

    final updated = orderRepo.orderById(createResult.value!.id, 'u-demo');
    expect(updated, isNotNull);
    expect(updated!.status, equals(OrderStatus.shipped));
    expect(updated.shipment, isNotNull);
    expect(updated.shipment!.trackingNo, equals('JNE-E2E-12345'));
    expect(updated.shipment!.courier, equals('JNE'));
  });
}
