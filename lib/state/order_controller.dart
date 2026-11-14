import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../core/result.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';

class OrderController extends ChangeNotifier {
  OrderController(this._orders, this._auth, [this._cart]);

  final OrderRepository _orders;
  final AuthController _auth;
  final CartController? _cart;

  List<Order> orders = const [];
  Order? selected;
  OrderStatus? statusFilter;
  bool loading = false;
  String? error;

  String? get _userId => _auth.user?.id;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      orders = const [];
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      await _orders.applyTimeBasedTransitions();
      orders = _orders.ordersFor(userId, status: statusFilter);
    } catch (_) {
      error = 'Gagal memuat pesanan.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String orderId) async {
    await _orders.applyTimeBasedTransitions();
    final userId = _userId;
    selected = userId == null ? null : _orders.orderById(orderId, userId);
    notifyListeners();
  }

  Future<AppResult<Order>> createOrder({
    required String addressId,
    required String paymentMethodId,
    String? idempotencyKey,
  }) async {
    final userId = _userId;
    if (userId == null) {
      notifyListeners();
      return AppResult<Order>.fail(
        const AppError(
          code: 'unauthenticated',
          message: 'Silakan masuk terlebih dahulu.',
        ),
      );
    }

    final result = await _orders.createOrder(
      userId: userId,
      addressId: addressId,
      paymentMethodId: paymentMethodId,
      idempotencyKey: idempotencyKey ?? newId('idem'),
    );
    if (result.isOk) {
      _cart?.clearLocal();
      selected = result.value;
      orders = _orders.ordersFor(userId, status: statusFilter);
    }
    notifyListeners();
    return result;
  }

  Future<AppResult<void>> uploadProof(
    String orderId,
    Uint8List bytes,
    String fileName,
  ) {
    final userId = _userId;
    if (userId == null) return Future.value(_guest());
    return _afterAction(
      () => _orders.uploadProof(
        orderId: orderId,
        userId: userId,
        bytes: bytes,
        fileName: fileName,
      ),
      orderId,
    );
  }

  Future<AppResult<void>> cancel(String orderId) {
    final userId = _userId;
    if (userId == null) return Future.value(_guest());
    return _afterAction(
      () => _orders.cancelByCustomer(orderId: orderId, userId: userId),
      orderId,
    );
  }

  Future<AppResult<void>> complete(String orderId) {
    final userId = _userId;
    if (userId == null) return Future.value(_guest());
    return _afterAction(
      () => _orders.completeByCustomer(orderId: orderId, userId: userId),
      orderId,
    );
  }

  Future<AppResult<void>> adminApprove(String orderId) {
    return _afterAction(
      () => _orders.adminApprovePayment(orderId: orderId),
      orderId,
    );
  }

  Future<AppResult<void>> adminReject(String orderId, String reason) {
    return _afterAction(
      () => _orders.adminRejectPayment(orderId: orderId, reason: reason),
      orderId,
    );
  }

  Future<AppResult<void>> adminShip(
    String orderId,
    String courier,
    String trackingNo,
  ) {
    return _afterAction(
      () => _orders.adminShip(
        orderId: orderId,
        courier: courier,
        trackingNo: trackingNo,
      ),
      orderId,
    );
  }

  Future<AppResult<void>> adminCancel(String orderId, String reason) {
    return _afterAction(
      () => _orders.adminCancel(orderId: orderId, reason: reason),
      orderId,
    );
  }

  Future<void> setStatusFilter(OrderStatus? status) {
    statusFilter = status;
    return load();
  }

  Future<void> applyTimedTransitions() async {
    await _orders.applyTimeBasedTransitions();
    final userId = _userId;
    if (userId != null) {
      orders = _orders.ordersFor(userId, status: statusFilter);
      final current = selected;
      if (current != null) {
        selected = _orders.orderById(current.id, userId);
      }
    }
    notifyListeners();
  }

  Future<AppResult<void>> _afterAction(
    Future<AppResult<void>> Function() action,
    String orderId,
  ) async {
    final result = await action();
    final userId = _userId;
    if (result.isOk && userId != null) {
      selected = _orders.orderById(orderId, userId);
      orders = _orders.ordersFor(userId, status: statusFilter);
    }
    notifyListeners();
    return result;
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
