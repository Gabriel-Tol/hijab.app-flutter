import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rnz_store/data/api_client.dart';
import 'package:rnz_store/data/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ApiClient performs silent login and sets bearer token', () async {
    final store = await LocalStore.open();
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'dummy_jwt_token', 'user': {'id': 2}}
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final client = ApiClient(
      client: mock,
      store: store,
      baseUrl: 'http://test.local',
    );
    final result = await client.ensureAuthenticated();
    expect(result.isOk, isTrue);
    expect(result.value, equals('dummy_jwt_token'));
    expect(client.token, equals('dummy_jwt_token'));
  });

  test('ApiClient checkout sends items, address, and payment method', () async {
    final store = await LocalStore.open();
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'jwt_token_123', 'user': {'id': 2}}
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/orders/checkout')) {
        expect(request.headers['Authorization'], equals('Bearer jwt_token_123'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['items'], isNotEmpty);
        expect(body['address']['city'], equals('Pontianak'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 12,
              'order_no': 'RNZ-261124-0012',
              'status': 'awaiting_payment',
              'total': 84000,
            }
          }),
          201,
        );
      }
      return http.Response('Not Found', 404);
    });

    final client = ApiClient(
      client: mock,
      store: store,
      baseUrl: 'http://test.local',
    );
    final result = await client.checkout(
      items: [
        {'variant_id': 1, 'qty': 1}
      ],
      address: {
        'recipient_name': 'Nadia',
        'city': 'Pontianak',
      },
      paymentMethod: {
        'provider': 'Bank BCA',
        'account_no': '1234567890',
      },
    );

    expect(result.isOk, isTrue);
    expect(result.value?['id'], equals(12));
    expect(result.value?['order_no'], equals('RNZ-261124-0012'));
  });

  test('ApiClient uploadPaymentProof sends multipart form data', () async {
    final store = await LocalStore.open();
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'token': 'jwt_token_123', 'user': {'id': 2}}
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/orders/12/proof')) {
        expect(request.headers['Authorization'], equals('Bearer jwt_token_123'));
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Bukti transfer berhasil diunggah'
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final client = ApiClient(
      client: mock,
      store: store,
      baseUrl: 'http://test.local',
    );
    final result = await client.uploadPaymentProof(
      orderId: 12,
      imageBytes: Uint8List.fromList([1, 2, 3, 4]),
      filename: 'proof.jpg',
    );

    expect(result.isOk, isTrue);
  });
}
