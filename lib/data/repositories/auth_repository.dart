import 'dart:math';

import '../../core/constants.dart';
import '../../core/ids.dart';
import '../../core/password_hasher.dart';
import '../../core/result.dart';
import '../../core/validators.dart';
import '../local_store.dart';
import '../models/address.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._store);

  static final Random _random = Random.secure();

  final LocalStore _store;

  User? currentUser() {
    final id = _store.sessionUserId;
    if (id == null) return null;
    for (final user in _users()) {
      if (user.id == id && user.status == 'active') return user;
    }
    return null;
  }

  List<Address> addressesFor(String userId) {
    return _addresses()
        .where((address) => address.userId == userId)
        .toList(growable: false);
  }

  Future<AppResult<User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AddressDraft address,
    DateTime? now,
  }) async {
    final normalizedEmail = Validators.normalizeEmail(email);
    final normalizedPhone = Validators.normalizePhone(phone);
    final fields = <String, String>{};

    void check(String key, String? message) {
      if (message != null) fields[key] = message;
    }

    check('name', Validators.name(name));
    check('email', Validators.email(email));
    check('phone', Validators.phone(phone));
    check('password', Validators.password(password));
    check(
      'label',
      Validators.required(address.label, 'Label alamat wajib diisi'),
    );
    check('recipientName', Validators.name(address.recipientName));
    check('recipientPhone', Validators.phone(address.recipientPhone));
    check(
      'province',
      Validators.required(address.province, 'Provinsi wajib diisi'),
    );
    check('city', Validators.required(address.city, 'Kota wajib diisi'));
    check(
      'district',
      Validators.required(address.district, 'Kecamatan wajib diisi'),
    );
    check(
      'addressLine',
      Validators.required(address.addressLine, 'Alamat lengkap wajib diisi'),
    );
    check('postalCode', Validators.postalCode(address.postalCode));

    if (fields.isNotEmpty) {
      return _fail<User>(
        'validation',
        'Periksa kembali data Anda.',
        fields,
      );
    }

    final users = _users();
    if (users.any(
      (user) => Validators.normalizeEmail(user.email) == normalizedEmail,
    )) {
      return _fail<User>('validation', 'Email sudah terdaftar.', {
        'email': 'Email sudah terdaftar',
      });
    }
    if (users.any(
      (user) => Validators.normalizePhone(user.phone) == normalizedPhone,
    )) {
      return _fail<User>('validation', 'Nomor telepon sudah terdaftar.', {
        'phone': 'Nomor telepon sudah terdaftar',
      });
    }

    final createdAt = now ?? DateTime.now();
    final salt = PasswordHasher.newSalt();
    final user = User(
      id: newId('u'),
      name: name.trim(),
      email: normalizedEmail,
      phone: normalizedPhone,
      passwordHash: PasswordHasher.hash(password, salt),
      passwordSalt: salt,
      createdAt: createdAt,
    );

    final firstAddress = Address(
      id: newId('a'),
      userId: user.id,
      label: address.label.trim(),
      recipientName: address.recipientName.trim(),
      recipientPhone: Validators.normalizePhone(address.recipientPhone),
      province: address.province.trim(),
      city: address.city.trim(),
      district: address.district.trim(),
      addressLine: address.addressLine.trim(),
      postalCode: address.postalCode.trim(),
      isDefault: true,
    );

    await _writeUsers([...users, user]);
    await _writeAddresses([..._addresses(), firstAddress]);
    await _store.setSessionUserId(user.id);
    return AppResult.ok(user);
  }

  Future<AppResult<User>> login({
    required String email,
    required String password,
    DateTime? now,
  }) async {
    final normalizedEmail = Validators.normalizeEmail(email);
    final nowValue = now ?? DateTime.now();
    final attempts = _store.map('login_attempts');
    final rawEntry = attempts[normalizedEmail];
    final entry = rawEntry is Map
        ? Map<String, dynamic>.from(rawEntry)
        : <String, dynamic>{};

    final lockedUntilRaw = entry['lockedUntil'] as String?;
    if (lockedUntilRaw != null) {
      final lockedUntil = DateTime.parse(lockedUntilRaw);
      if (lockedUntil.isAfter(nowValue)) {
        final minutes = (lockedUntil.difference(nowValue).inSeconds / 60).ceil();
        return _fail<User>(
          'locked',
          'Terlalu banyak percobaan. Coba lagi dalam $minutes menit.',
        );
      }
      entry.remove('count');
      entry.remove('lockedUntil');
    }

    final user = _findByEmail(_users(), normalizedEmail);
    final valid =
        user != null &&
        user.status == 'active' &&
        PasswordHasher.verify(password, user.passwordSalt, user.passwordHash);

    if (!valid) {
      final count = (entry['count'] as int? ?? 0) + 1;
      entry['count'] = count;
      final locked = count >= AppConstants.loginMaxAttempts;
      if (locked) {
        entry['lockedUntil'] = nowValue
            .add(AppConstants.loginLockout)
            .toIso8601String();
      }
      attempts[normalizedEmail] = entry;
      await _store.write('login_attempts', attempts);
      if (locked) {
        return _fail<User>(
          'locked',
          'Terlalu banyak percobaan. Akun terkunci selama 15 menit.',
        );
      }
      return _fail<User>(
        'invalid_credentials',
        'Email atau kata sandi salah.',
      );
    }

    attempts.remove(normalizedEmail);
    await _store.write('login_attempts', attempts);
    await _store.setSessionUserId(user.id);
    return AppResult.ok(user);
  }

  Future<void> logout() async {
    await _store.setSessionUserId(null);
  }

  Future<AppResult<String?>> requestResetCode(
    String email, {
    DateTime? now,
  }) async {
    final normalizedEmail = Validators.normalizeEmail(email);
    final user = _findByEmail(_users(), normalizedEmail);
    if (user == null || user.status != 'active') {
      return AppResult<String?>.ok(null);
    }

    final code = (_random.nextInt(900000) + 100000).toString();
    final salt = PasswordHasher.newSalt();
    final codes = _store.map('reset_codes');
    codes[normalizedEmail] = {
      'codeHash': PasswordHasher.hash(code, salt),
      'salt': salt,
      'expiresAt': (now ?? DateTime.now())
          .add(AppConstants.resetCodeLifetime)
          .toIso8601String(),
      'usedAt': null,
    };
    await _store.write('reset_codes', codes);
    return AppResult.ok(code);
  }

  Future<AppResult<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    DateTime? now,
  }) async {
    final normalizedEmail = Validators.normalizeEmail(email);
    final nowValue = now ?? DateTime.now();
    final codes = _store.map('reset_codes');
    final rawEntry = codes[normalizedEmail];
    if (rawEntry is! Map) {
      return _fail<void>('invalid_code', 'Kode reset tidak valid.');
    }

    final entry = Map<String, dynamic>.from(rawEntry);
    if (entry['usedAt'] != null) {
      return _fail<void>('used', 'Kode reset sudah digunakan.');
    }
    final expiresAt = DateTime.parse(entry['expiresAt'] as String);
    if (!expiresAt.isAfter(nowValue)) {
      return _fail<void>('expired', 'Kode reset sudah kedaluwarsa.');
    }
    final validCode = PasswordHasher.verify(
      code,
      entry['salt'] as String,
      entry['codeHash'] as String,
    );
    if (!validCode) {
      return _fail<void>('invalid_code', 'Kode reset tidak valid.');
    }

    final passwordError = Validators.password(newPassword);
    if (passwordError != null) {
      return _fail<void>('validation', 'Periksa kembali data Anda.', {
        'password': passwordError,
      });
    }

    final users = _users();
    final user = _findByEmail(users, normalizedEmail);
    if (user == null) {
      return _fail<void>('invalid_code', 'Kode reset tidak valid.');
    }

    final salt = PasswordHasher.newSalt();
    final updated = user.copyWith(
      passwordHash: PasswordHasher.hash(newPassword, salt),
      passwordSalt: salt,
    );
    await _writeUsers(
      users
          .map((item) => item.id == user.id ? updated : item)
          .toList(growable: false),
    );

    entry['usedAt'] = nowValue.toIso8601String();
    codes[normalizedEmail] = entry;
    await _store.write('reset_codes', codes);

    if (_store.sessionUserId == user.id) {
      await _store.setSessionUserId(null);
    }
    return AppResult<void>.ok(null);
  }

  List<User> _users() {
    return _store
        .list('users')
        .map((raw) => User.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  List<Address> _addresses() {
    return _store
        .list('addresses')
        .map((raw) => Address.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeUsers(List<User> users) async {
    await _store.write(
      'users',
      users.map((user) => user.toJson()).toList(growable: false),
    );
  }

  Future<void> _writeAddresses(List<Address> addresses) async {
    await _store.write(
      'addresses',
      addresses.map((address) => address.toJson()).toList(growable: false),
    );
  }

  User? _findByEmail(List<User> users, String normalizedEmail) {
    for (final user in users) {
      if (Validators.normalizeEmail(user.email) == normalizedEmail) {
        return user;
      }
    }
    return null;
  }

  AppResult<T> _fail<T>(
    String code,
    String message, [
    Map<String, String> fields = const {},
  ]) {
    return AppResult<T>.fail(
      AppError(code: code, message: message, fields: fields),
    );
  }
}
