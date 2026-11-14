import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/cart.dart';
import '../data/repositories/cart_repository.dart';
import 'auth_controller.dart';

class CartController extends ChangeNotifier {
  CartController(this._cart, this._auth);

  final CartRepository _cart;
  final AuthController _auth;

  List<CartLine> lines = const [];
  List<String> warnings = const [];
  bool loading = false;

  int get count => lines.fold(0, (sum, line) => sum + line.qty);

  int get subtotal => lines.fold(0, (sum, line) => sum + line.lineTotal);

  String? get _userId => _auth.user?.id;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      clearLocal();
      return;
    }

    loading = true;
    notifyListeners();
    try {
      warnings = _cart.reconcile(userId);
      lines = _cart.lines(userId);
    } catch (_) {
      warnings = const [];
      lines = const [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  AppResult<void> add(String variantId, {int qty = 1}) {
    final userId = _userId;
    if (userId == null) return _guest();

    final result = _cart.add(userId, variantId, qty: qty);
    if (result.isOk) {
      warnings = const [];
      lines = _cart.lines(userId);
    }
    notifyListeners();
    return result;
  }

  AppResult<void> setQty(String variantId, int qty) {
    final userId = _userId;
    if (userId == null) return _guest();

    final result = _cart.setQty(userId, variantId, qty);
    if (result.isOk) {
      warnings = const [];
      lines = _cart.lines(userId);
    }
    notifyListeners();
    return result;
  }

  Future<void> remove(String variantId) async {
    final userId = _userId;
    if (userId == null) return;
    await _cart.remove(userId, variantId);
    lines = _cart.lines(userId);
    notifyListeners();
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) return;
    await _cart.clear(userId);
    clearLocal();
  }

  void clearLocal() {
    lines = const [];
    warnings = const [];
    notifyListeners();
  }

  AppResult<void> _guest() {
    return AppResult<void>.fail(
      const AppError(
        code: 'unauthenticated',
        message: 'Silakan masuk terlebih dahulu.',
      ),
    );
  }
}
