import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static final Random _random = Random.secure();

  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  static bool verify(String password, String salt, String hash) {
    return PasswordHasher.hash(password, salt) == hash;
  }
}
