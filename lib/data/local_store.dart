import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'seed_data.dart';

class StoreCorruptException implements Exception {
  StoreCorruptException(this.key, [this.cause]);

  final String key;
  final Object? cause;

  @override
  String toString() => 'Data lokal tidak dapat dibaca: $key';
}

class LocalStore {
  LocalStore._(this._prefs);

  static const String _prefix = AppConstants.prefPrefix;

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    return LocalStore._(await SharedPreferences.getInstance());
  }

  String _key(String key) => '$_prefix$key';

  List<dynamic> list(String key) {
    final raw = _prefs.getString(_key(key));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Bukan list');
      return decoded;
    } on FormatException catch (error) {
      throw StoreCorruptException(key, error);
    }
  }

  Map<String, dynamic> map(String key) {
    final raw = _prefs.getString(_key(key));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Bukan objek');
      return Map<String, dynamic>.from(decoded);
    } on FormatException catch (error) {
      throw StoreCorruptException(key, error);
    }
  }

  String? string(String key) => _prefs.getString(_key(key));

  bool flag(String key) => _prefs.getBool(_key(key)) ?? false;

  Future<void> write(String key, Object? value) async {
    await _prefs.setString(_key(key), jsonEncode(value));
  }

  Future<void> remove(String key) async {
    await _prefs.remove(_key(key));
  }

  Future<void> clearAll() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  bool get onboardingSeen =>
      _prefs.getBool(_key('onboarding_seen')) ?? false;

  Future<void> setOnboardingSeen() async {
    await _prefs.setBool(_key('onboarding_seen'), true);
  }

  String? get sessionUserId => map('session')['userId'] as String?;

  Future<void> setSessionUserId(String? id) async {
    if (id == null) {
      await remove('session');
    } else {
      await write('session', {'userId': id});
    }
  }

  String? proof(String key) => _prefs.getString(_key(key));

  Future<void> setProof(String key, String dataUrl) async {
    await _prefs.setString(_key(key), dataUrl);
  }

  Future<void> removeProof(String key) async {
    await _prefs.remove(_key(key));
  }

  Future<void> seedIfNeeded() async {
    final version = _prefs.getString(_key('seed_version'));
    if (version == AppConstants.seedVersion) return;
    await SeedData.run(this);
    await _prefs.setString(_key('seed_version'), AppConstants.seedVersion);
  }
}
