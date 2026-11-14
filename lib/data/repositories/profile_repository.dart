import '../../core/constants.dart';
import '../../core/ids.dart';
import '../../core/password_hasher.dart';
import '../../core/result.dart';
import '../../core/validators.dart';
import '../local_store.dart';
import '../models/address.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'auth_repository.dart';

class ProfileRepository {
  ProfileRepository(LocalStore store)
      : _store = store,
        _auth = AuthRepository(store);

  final LocalStore _store;
  final AuthRepository _auth;

  User? currentUser() => _auth.currentUser();

  List<Address> addresses(String userId) => _auth.addressesFor(userId);

  Address? defaultAddress(String userId) {
    for (final address in addresses(userId)) {
      if (address.isDefault) return address;
    }
    return null;
  }

  Address? addressById(String userId, String id) {
    for (final address in addresses(userId)) {
      if (address.id == id) return address;
    }
    return null;
  }

  Future<AppResult<User>> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = currentUser();
    if (user == null) {
      return _fail<User>('unauthenticated', 'Silakan masuk terlebih dahulu.');
    }

    final fields = <String, String>{};
    final nameError = Validators.name(name);
    if (nameError != null) fields['name'] = nameError;
    final phoneError = Validators.phone(phone);
    if (phoneError != null) fields['phone'] = phoneError;
    if (fields.isNotEmpty) {
      return _fail<User>('validation', 'Periksa kembali data Anda.', fields);
    }

    final normalizedPhone = Validators.normalizePhone(phone);
    final users = _users();
    final taken = users.any(
      (other) =>
          other.id != user.id &&
          Validators.normalizePhone(other.phone) == normalizedPhone,
    );
    if (taken) {
      return _fail<User>('validation', 'Nomor telepon sudah terdaftar.', {
        'phone': 'Nomor telepon sudah terdaftar',
      });
    }

    final updated = user.copyWith(
      name: name.trim(),
      phone: normalizedPhone,
    );
    await _writeUsers(
      users
          .map((item) => item.id == user.id ? updated : item)
          .toList(growable: false),
    );
    return AppResult.ok(updated);
  }

  Future<AppResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser();
    if (user == null) {
      return _fail<void>('unauthenticated', 'Silakan masuk terlebih dahulu.');
    }
    if (!PasswordHasher.verify(
      currentPassword,
      user.passwordSalt,
      user.passwordHash,
    )) {
      return _fail<void>(
        'invalid_password',
        'Kata sandi saat ini tidak sesuai.',
        {'currentPassword': 'Kata sandi saat ini tidak sesuai'},
      );
    }

    final passwordError = Validators.password(newPassword);
    if (passwordError != null) {
      return _fail<void>('validation', 'Periksa kembali data Anda.', {
        'password': passwordError,
      });
    }
    if (newPassword == currentPassword) {
      return _fail<void>('validation', 'Kata sandi baru harus berbeda.', {
        'password': 'Kata sandi baru harus berbeda dari yang lama',
      });
    }

    final salt = PasswordHasher.newSalt();
    final updated = user.copyWith(
      passwordHash: PasswordHasher.hash(newPassword, salt),
      passwordSalt: salt,
    );
    await _writeUsers(
      _users()
          .map((item) => item.id == user.id ? updated : item)
          .toList(growable: false),
    );
    return AppResult<void>.ok(null);
  }

  Future<AppResult<void>> deleteAccount({
    required String password,
    DateTime? now,
  }) async {
    final user = currentUser();
    if (user == null) {
      return _fail<void>('unauthenticated', 'Silakan masuk terlebih dahulu.');
    }
    if (!PasswordHasher.verify(
      password,
      user.passwordSalt,
      user.passwordHash,
    )) {
      return _fail<void>('invalid_password', 'Kata sandi tidak sesuai.');
    }

    final orders = _orders();
    if (orders.any((order) => order.userId == user.id && !order.status.isFinal)) {
      return _fail<void>(
        'active_orders',
        'Tidak dapat menghapus akun selama masih ada pesanan aktif.',
      );
    }

    final anonymized = user.copyWith(
      name: 'Pelanggan',
      email: 'deleted-${user.id}@rnz.local',
      phone: 'deleted-${user.id}',
      passwordHash: '',
      passwordSalt: '',
      status: 'deleted',
      deletedAt: now ?? DateTime.now(),
    );
    await _writeUsers(
      _users()
          .map((item) => item.id == user.id ? anonymized : item)
          .toList(growable: false),
    );
    await _writeAddresses(
      _allAddresses()
          .where((address) => address.userId != user.id)
          .toList(growable: false),
    );
    await _writeOrders(
      orders.map((order) {
        if (order.userId != user.id) return order;
        return order.copyWith(
          addressSnapshot: {
            for (final key in order.addressSnapshot.keys) key: 'Dianonimkan',
          },
        );
      }).toList(growable: false),
    );
    await _store.setSessionUserId(null);
    return AppResult<void>.ok(null);
  }

  Future<AppResult<Address>> addAddress(
    String userId,
    AddressDraft draft,
  ) async {
    final fields = _addressErrors(draft);
    if (fields.isNotEmpty) {
      return _fail<Address>('validation', 'Periksa kembali data Anda.', fields);
    }

    final existing = addresses(userId);
    if (existing.length >= AppConstants.maxAddresses) {
      return _fail<Address>(
        'address_limit',
        'Maksimal 5 alamat. Hapus salah satu alamat terlebih dahulu.',
      );
    }

    final address = Address(
      id: newId('a'),
      userId: userId,
      label: draft.label.trim(),
      recipientName: draft.recipientName.trim(),
      recipientPhone: Validators.normalizePhone(draft.recipientPhone),
      province: draft.province.trim(),
      city: draft.city.trim(),
      district: draft.district.trim(),
      addressLine: draft.addressLine.trim(),
      postalCode: draft.postalCode.trim(),
      isDefault: existing.isEmpty,
    );
    await _writeAddresses([..._allAddresses(), address]);
    return AppResult.ok(address);
  }

  Future<AppResult<Address>> updateAddress(
    String userId,
    Address address,
  ) async {
    final existing = addressById(userId, address.id);
    if (existing == null) {
      return _fail<Address>('not_found', 'Alamat tidak ditemukan.');
    }

    final fields = _addressErrors(
      AddressDraft(
        label: address.label,
        recipientName: address.recipientName,
        recipientPhone: address.recipientPhone,
        province: address.province,
        city: address.city,
        district: address.district,
        addressLine: address.addressLine,
        postalCode: address.postalCode,
      ),
    );
    if (fields.isNotEmpty) {
      return _fail<Address>('validation', 'Periksa kembali data Anda.', fields);
    }

    final makeDefault = address.isDefault || existing.isDefault;
    final updated = Address(
      id: existing.id,
      userId: userId,
      label: address.label.trim(),
      recipientName: address.recipientName.trim(),
      recipientPhone: Validators.normalizePhone(address.recipientPhone),
      province: address.province.trim(),
      city: address.city.trim(),
      district: address.district.trim(),
      addressLine: address.addressLine.trim(),
      postalCode: address.postalCode.trim(),
      isDefault: makeDefault,
    );

    final next = <Address>[];
    for (final item in _allAddresses()) {
      if (item.id == existing.id && item.userId == userId) {
        next.add(updated);
      } else if (makeDefault && item.userId == userId) {
        next.add(item.copyWith(isDefault: false));
      } else {
        next.add(item);
      }
    }
    await _writeAddresses(next);
    return AppResult.ok(updated);
  }

  Future<AppResult<void>> deleteAddress(String userId, String id) async {
    final existing = addressById(userId, id);
    if (existing == null) {
      return _fail<void>('not_found', 'Alamat tidak ditemukan.');
    }

    var promoted = false;
    final next = <Address>[];
    for (final item in _allAddresses()) {
      if (item.userId == userId && item.id == id) continue;
      if (existing.isDefault && !promoted && item.userId == userId) {
        next.add(item.copyWith(isDefault: true));
        promoted = true;
      } else {
        next.add(item);
      }
    }
    await _writeAddresses(next);
    return AppResult<void>.ok(null);
  }

  Future<AppResult<void>> setDefaultAddress(String userId, String id) async {
    final all = _allAddresses();
    final exists = all.any(
      (address) => address.userId == userId && address.id == id,
    );
    if (!exists) {
      return _fail<void>('not_found', 'Alamat tidak ditemukan.');
    }
    await _writeAddresses(
      all
          .map(
            (address) => address.userId == userId
                ? address.copyWith(isDefault: address.id == id)
                : address,
          )
          .toList(growable: false),
    );
    return AppResult<void>.ok(null);
  }

  Map<String, String> _addressErrors(AddressDraft draft) {
    final fields = <String, String>{};

    void check(String key, String? message) {
      if (message != null) fields[key] = message;
    }

    check('label', Validators.required(draft.label, 'Label alamat wajib diisi'));
    check('recipientName', Validators.name(draft.recipientName));
    check('recipientPhone', Validators.phone(draft.recipientPhone));
    check(
      'province',
      Validators.required(draft.province, 'Provinsi wajib diisi'),
    );
    check('city', Validators.required(draft.city, 'Kota wajib diisi'));
    check(
      'district',
      Validators.required(draft.district, 'Kecamatan wajib diisi'),
    );
    check(
      'addressLine',
      Validators.required(draft.addressLine, 'Alamat lengkap wajib diisi'),
    );
    check('postalCode', Validators.postalCode(draft.postalCode));
    return fields;
  }

  List<Address> _allAddresses() {
    return _store
        .list('addresses')
        .map((raw) => Address.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeAddresses(List<Address> addresses) async {
    await _store.write(
      'addresses',
      addresses.map((address) => address.toJson()).toList(growable: false),
    );
  }

  List<User> _users() {
    return _store
        .list('users')
        .map((raw) => User.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeUsers(List<User> users) async {
    await _store.write(
      'users',
      users.map((user) => user.toJson()).toList(growable: false),
    );
  }

  List<Order> _orders() {
    return _store
        .list('orders')
        .map((raw) => Order.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeOrders(List<Order> orders) async {
    await _store.write(
      'orders',
      orders.map((order) => order.toJson()).toList(growable: false),
    );
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
