import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/address.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._auth, this._profile) : _user = _auth.currentUser();

  final AuthRepository _auth;
  final ProfileRepository _profile;

  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  Address? get defaultAddress {
    final id = _user?.id;
    return id == null ? null : _profile.defaultAddress(id);
  }

  Future<AppResult<User>> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.login(email: email, password: password);
    if (result.isOk) _user = result.value;
    notifyListeners();
    return result;
  }

  Future<AppResult<User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AddressDraft address,
  }) async {
    final result = await _auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      address: address,
    );
    if (result.isOk) _user = result.value;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  Future<AppResult<String?>> requestResetCode(String email) {
    return _auth.requestResetCode(email);
  }

  Future<AppResult<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _auth.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }

  void refresh() {
    _user = _auth.currentUser();
    notifyListeners();
  }
}
