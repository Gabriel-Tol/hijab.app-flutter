import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/result.dart';
import 'local_store.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    required LocalStore store,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _store = store,
        _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final LocalStore _store;
  final String _baseUrl;

  String? _token;
  String? get token => _token;

  String get apiUrl => '$_baseUrl/api/v1';

  Future<AppResult<String>> ensureAuthenticated() async {
    if (_token != null && _token!.isNotEmpty) {
      return AppResult.ok(_token!);
    }

    final storedToken = _store.string('api_jwt_token');
    if (storedToken != null && storedToken.isNotEmpty) {
      _token = storedToken;
      return AppResult.ok(_token!);
    }

    // Auto-login with customer demo account
    return login('nadia@rnzstore.id', 'Hijab1234');
  }

  Future<AppResult<String>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$apiUrl/auth/login');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = decoded['data']?['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _token = token;
          await _store.write('api_jwt_token', token);
          return AppResult.ok(token);
        }
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal login ke server API (${response.statusCode})';
      return AppResult.fail(AppError(code: 'auth_error', message: message));
    } catch (e) {
      return AppResult.fail(
        AppError(code: 'network_error', message: 'Koneksi ke backend gagal: $e'),
      );
    }
  }

  Future<AppResult<Map<String, dynamic>>> checkout({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> address,
    required Map<String, dynamic> paymentMethod,
  }) async {
    final authRes = await ensureAuthenticated();
    if (!authRes.isOk) {
      return AppResult.fail(authRes.error!);
    }

    try {
      final uri = Uri.parse('$apiUrl/orders/checkout');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'items': items,
          'address': address,
          'payment_method': paymentMethod,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data != null) {
          return AppResult.ok(data);
        }
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Checkout gagal di server (${response.statusCode})';
      return AppResult.fail(AppError(code: 'checkout_error', message: message));
    } catch (e) {
      return AppResult.fail(
        AppError(code: 'network_error', message: 'Gagal menghubungi server: $e'),
      );
    }
  }

  Future<AppResult<void>> uploadPaymentProof({
    required int orderId,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final authRes = await ensureAuthenticated();
    if (!authRes.isOk) {
      return AppResult.fail(authRes.error!);
    }

    try {
      final uri = Uri.parse('$apiUrl/orders/$orderId/proof');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'proof',
          imageBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AppResult.ok(null);
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal mengunggah bukti bayar (${response.statusCode})';
      return AppResult.fail(AppError(code: 'upload_error', message: message));
    } catch (e) {
      return AppResult.fail(
        AppError(code: 'network_error', message: 'Gagal mengunggah bukti: $e'),
      );
    }
  }

  Future<AppResult<List<dynamic>>> fetchOrders() async {
    final authRes = await ensureAuthenticated();
    if (!authRes.isOk) {
      return AppResult.fail(authRes.error!);
    }

    try {
      final uri = Uri.parse('$apiUrl/orders');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final list = decoded['data'] as List<dynamic>?;
        if (list != null) {
          return AppResult.ok(list);
        }
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal memuat pesanan (${response.statusCode})';
      return AppResult.fail(AppError(code: 'fetch_error', message: message));
    } catch (e) {
      return AppResult.fail(
        AppError(code: 'network_error', message: 'Gagal memuat pesanan: $e'),
      );
    }
  }
}
