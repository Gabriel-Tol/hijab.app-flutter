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

  String _sanitizeToken(String token) {
    var t = token.trim();
    if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
      t = t.substring(1, t.length - 1).trim();
    }
    return t;
  }

  Future<AppResult<String>> ensureAuthenticated() async {
    if (_token != null && _token!.isNotEmpty) {
      _token = _sanitizeToken(_token!);
      return AppResult.ok(_token!);
    }

    final readToken = _store.string('api_jwt_token');
    if (readToken != null && readToken.isNotEmpty) {
      _token = _sanitizeToken(readToken);
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
          final cleanToken = _sanitizeToken(token);
          _token = cleanToken;
          await _store.write('api_jwt_token', cleanToken);
          return AppResult.ok(cleanToken);
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
      var response = await _client.post(
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

      // Otomatis refresh sesi jika token kedaluwarsa (401)
      if (response.statusCode == 401) {
        _token = null;
        await _store.remove('api_jwt_token');
        final reauth = await ensureAuthenticated();
        if (reauth.isOk) {
          response = await _client.post(
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
        }
      }

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
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'proof',
          imageBytes,
          filename: filename,
        ),
      );

      var streamedResponse = await _client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        _token = null;
        await _store.remove('api_jwt_token');
        final reauth = await ensureAuthenticated();
        if (reauth.isOk) {
          request = http.MultipartRequest('POST', uri);
          request.headers['Authorization'] = 'Bearer $_token';
          request.files.add(
            http.MultipartFile.fromBytes(
              'proof',
              imageBytes,
              filename: filename,
            ),
          );
          streamedResponse = await _client.send(request);
          response = await http.Response.fromStream(streamedResponse);
        }
      }

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
      var response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 401) {
        _token = null;
        await _store.remove('api_jwt_token');
        final reauth = await ensureAuthenticated();
        if (reauth.isOk) {
          response = await _client.get(
            uri,
            headers: {
              'Authorization': 'Bearer $_token',
            },
          );
        }
      }

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
