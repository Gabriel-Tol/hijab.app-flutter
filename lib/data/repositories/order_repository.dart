import 'dart:convert';
import 'dart:typed_data';

import '../../core/constants.dart';
import '../../core/ids.dart';
import '../../core/result.dart';
import '../local_store.dart';
import '../models/address.dart';
import '../models/catalog.dart';
import '../models/master.dart';
import '../models/order.dart';
import 'cart_repository.dart';
import 'checkout_repository.dart';
import 'profile_repository.dart';

class OrderRepository {
  OrderRepository(this._store, this._cart, this._profile, this._checkout);

  final LocalStore _store;
  final CartRepository _cart;
  final ProfileRepository _profile;
  final CheckoutRepository _checkout;

  List<Order> ordersFor(String userId, {OrderStatus? status}) {
    final orders = _orders()
        .where(
          (order) =>
              order.userId == userId &&
              (status == null || order.status == status),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Order? orderById(String orderId, String userId) {
    for (final order in _orders()) {
      if (order.id == orderId && order.userId == userId) return order;
    }
    return null;
  }

  String? proofDataUrl(PaymentProof proof) => _store.proof(proof.storageKey);

  Future<void> applyTimeBasedTransitions({DateTime? now}) async {
    final nowValue = now ?? DateTime.now();
    final next = <Order>[];
    final restored = <String, int>{};
    var ordersChanged = false;
    var stockChanged = false;

    for (final order in _orders()) {
      if (order.status == OrderStatus.awaitingPayment &&
          !order.payBefore.isAfter(nowValue)) {
        ordersChanged = true;
        stockChanged = true;
        _addStock(restored, order.items);
        next.add(
          order.copyWith(
            status: OrderStatus.cancelled,
            statusLogs: [
              ...order.statusLogs,
              _log(
                from: order.status,
                to: OrderStatus.cancelled,
                note: 'Kedaluwarsa',
                actor: ActorType.system,
                at: nowValue,
              ),
            ],
          ),
        );
        continue;
      }

      final shipment = order.shipment;
      if (order.status == OrderStatus.shipped && shipment != null) {
        final completedAt = shipment.shippedAt.add(
          AppConstants.autoCompleteAfter,
        );
        if (!completedAt.isAfter(nowValue)) {
          ordersChanged = true;
          next.add(
            order.copyWith(
              status: OrderStatus.completed,
              completedAt: completedAt,
              statusLogs: [
                ...order.statusLogs,
                _log(
                  from: order.status,
                  to: OrderStatus.completed,
                  note: 'Selesai otomatis setelah 7 hari',
                  actor: ActorType.system,
                  at: nowValue,
                ),
              ],
            ),
          );
          continue;
        }
      }

      next.add(order);
    }

    if (!ordersChanged) return;
    if (stockChanged) await _restoreStock(restored);
    await _writeOrders(next);
  }

  Future<AppResult<void>> uploadProof({
    required String orderId,
    required String userId,
    required Uint8List bytes,
    required String fileName,
    DateTime? now,
  }) async {
    final orders = _orders();
    final index = _indexOf(orders, orderId, userId);
    if (index < 0) return _fail('not_found', 'Pesanan tidak ditemukan.');
    final order = orders[index];
    if (order.status != OrderStatus.awaitingPayment) {
      return _fail('invalid_transition', 'Transisi status tidak valid.');
    }
    if (bytes.length > AppConstants.maxProofBytes) {
      return _fail('file_too_large', 'Ukuran file melebihi 5 MB.');
    }
    final mime = _imageMime(bytes);
    if (mime == null) {
      return _fail(
        'invalid_type',
        'Format file tidak didukung. Gunakan JPG, PNG, atau WEBP.',
      );
    }

    final uploadedAt = now ?? DateTime.now();
    final proofId = newId('pr');
    final storageKey = 'proof.${order.id}.$proofId';
    await _store.setProof(
      storageKey,
      'data:$mime;base64,${base64Encode(bytes)}',
    );

    final proof = PaymentProof(
      id: proofId,
      storageKey: storageKey,
      status: PaymentProofStatus.pending,
      uploadedAt: uploadedAt,
    );
    final updated = order.copyWith(
      status: OrderStatus.paymentVerification,
      proofs: [...order.proofs, proof],
      latestRejectReason: null,
      statusLogs: [
        ...order.statusLogs,
        _log(
          from: order.status,
          to: OrderStatus.paymentVerification,
          note: 'Bukti pembayaran diunggah',
          actor: ActorType.customer,
          at: uploadedAt,
        ),
      ],
    );
    final next = [...orders];
    next[index] = updated;
    await _writeOrders(next);
    return AppResult<void>.ok(null);
  }

  Future<AppResult<void>> cancelByCustomer({
    required String orderId,
    required String userId,
    DateTime? now,
  }) {
    return _commitTransition(
      orderId: orderId,
      userId: userId,
      from: const {OrderStatus.awaitingPayment},
      to: OrderStatus.cancelled,
      note: 'Dibatalkan pelanggan',
      actor: ActorType.customer,
      at: now ?? DateTime.now(),
      restoreStock: true,
    );
  }

  Future<AppResult<void>> completeByCustomer({
    required String orderId,
    required String userId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return _commitTransition(
      orderId: orderId,
      userId: userId,
      from: const {OrderStatus.shipped},
      to: OrderStatus.completed,
      note: 'Pesanan diterima pelanggan',
      actor: ActorType.customer,
      at: at,
      transform: (order) => order.copyWith(completedAt: at),
    );
  }

  Future<AppResult<void>> adminApprovePayment({
    required String orderId,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return _commitTransition(
      orderId: orderId,
      from: const {OrderStatus.paymentVerification},
      to: OrderStatus.processing,
      note: 'Pembayaran diverifikasi',
      actor: ActorType.admin,
      at: at,
      transform: (order) => order.copyWith(
        proofs: _reviewProofs(
          order.proofs,
          PaymentProofStatus.approved,
          at,
          null,
        ),
        latestRejectReason: null,
      ),
    );
  }

  Future<AppResult<void>> adminRejectPayment({
    required String orderId,
    required String reason,
    DateTime? now,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        _fail('validation', 'Alasan penolakan wajib diisi.', {
          'reason': 'Alasan penolakan wajib diisi',
        }),
      );
    }
    final at = now ?? DateTime.now();
    return _commitTransition(
      orderId: orderId,
      from: const {OrderStatus.paymentVerification},
      to: OrderStatus.awaitingPayment,
      note: 'Pembayaran ditolak: $trimmed',
      actor: ActorType.admin,
      at: at,
      transform: (order) => order.copyWith(
        proofs: _reviewProofs(
          order.proofs,
          PaymentProofStatus.rejected,
          at,
          trimmed,
        ),
        latestRejectReason: trimmed,
      ),
    );
  }

  Future<AppResult<void>> adminShip({
    required String orderId,
    required String courier,
    required String trackingNo,
    DateTime? now,
  }) {
    final fields = <String, String>{};
    if (!AppConstants.couriers.contains(courier)) {
      fields['courier'] = 'Ekspedisi tidak valid';
    }
    if (!RegExp(r'^[A-Za-z0-9]{5,30}$').hasMatch(trackingNo)) {
      fields['trackingNo'] = 'Nomor resi harus 5–30 karakter alfanumerik';
    }
    if (fields.isNotEmpty) {
      return Future.value(
        _fail('validation', 'Periksa kembali data pengiriman.', fields),
      );
    }

    final at = now ?? DateTime.now();
    return _commitTransition(
      orderId: orderId,
      from: const {OrderStatus.processing},
      to: OrderStatus.shipped,
      note: 'Dikirim dengan $courier',
      actor: ActorType.admin,
      at: at,
      transform: (order) => order.copyWith(
        shipment: Shipment(
          courier: courier,
          trackingNo: trackingNo,
          shippedAt: at,
        ),
      ),
    );
  }

  Future<AppResult<void>> adminCancel({
    required String orderId,
    required String reason,
    DateTime? now,
  }) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        _fail('validation', 'Alasan pembatalan wajib diisi.', {
          'reason': 'Alasan pembatalan wajib diisi',
        }),
      );
    }
    return _commitTransition(
      orderId: orderId,
      from: const {OrderStatus.paymentVerification, OrderStatus.processing},
      to: OrderStatus.cancelled,
      note: 'Dibatalkan admin: $trimmed',
      actor: ActorType.admin,
      at: now ?? DateTime.now(),
      restoreStock: true,
    );
  }

  Future<AppResult<Order>> createOrder({
    required String userId,
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
    DateTime? now,
  }) async {
    final existing = _orders().where(
      (order) =>
          order.userId == userId && order.idempotencyKey == idempotencyKey,
    );
    if (existing.isNotEmpty) return AppResult.ok(existing.first);

    final address = _profile.addressById(userId, addressId);
    if (address == null) {
      return _fail<Order>('address', 'Alamat tidak ditemukan.');
    }
    final method = _checkout.paymentMethodById(paymentMethodId);
    if (method == null) {
      return _fail<Order>(
        'payment',
        'Metode pembayaran tidak tersedia.',
      );
    }

    final lines = _cart.lines(userId);
    if (lines.isEmpty) {
      return _fail<Order>('empty_cart', 'Keranjang masih kosong.');
    }

    final shortages = <String, String>{};
    for (final line in lines) {
      if (line.qty > line.variant.stock) {
        shortages[line.variant.id] = 'Stok tersisa ${line.variant.stock}';
      }
    }
    if (shortages.isNotEmpty) {
      return _fail<Order>(
        'stock',
        'Stok beberapa produk tidak mencukupi.',
        shortages,
      );
    }

    final createdAt = now ?? DateTime.now();
    final subtotal = lines.fold(0, (sum, line) => sum + line.lineTotal);
    final rate = _checkout.rateForCity(address.city);
    final shippingCost = rate?.cost ?? 0;
    final orderNo = _nextOrderNo(createdAt);

    final touched = lines.map((line) => line.variant.id).toSet();
    final nextProducts = _products().map((product) {
      if (!product.variants.any((variant) => touched.contains(variant.id))) {
        return product;
      }
      return product.copyWith(
        variants: product.variants.map((variant) {
          if (!touched.contains(variant.id)) return variant;
          final line = lines.firstWhere(
            (item) => item.variant.id == variant.id,
          );
          return variant.copyWith(stock: variant.stock - line.qty);
        }).toList(growable: false),
      );
    }).toList(growable: false);
    await _writeProducts(nextProducts);

    final order = Order(
      id: newId('o'),
      orderNo: orderNo,
      userId: userId,
      status: OrderStatus.awaitingPayment,
      subtotal: subtotal,
      shippingCost: shippingCost,
      shippingNote: rate == null ? 'Ongkir dikonfirmasi admin' : null,
      total: subtotal + shippingCost,
      addressSnapshot: _addressSnapshot(address),
      paymentMethodSnapshot: _paymentSnapshot(method),
      payBefore: createdAt.add(AppConstants.paymentWindow),
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
      items: lines
          .map(
            (line) => OrderItem(
              productId: line.product.id,
              variantId: line.variant.id,
              productName: line.product.name,
              variantLabel: line.variant.label,
              unitPrice: line.product.price,
              qty: line.qty,
              lineTotal: line.lineTotal,
              imageAsset: line.product.images.isEmpty
                  ? ''
                  : line.product.images.first,
            ),
          )
          .toList(growable: false),
      statusLogs: [
        StatusLog(
          id: newId('log'),
          toStatus: OrderStatus.awaitingPayment,
          note: 'Pesanan dibuat',
          actor: ActorType.customer,
          createdAt: createdAt,
        ),
      ],
    );

    await _writeOrders([..._orders(), order]);
    await _cart.clear(userId);
    return AppResult.ok(order);
  }

  String _nextOrderNo(DateTime date) {
    final stamp =
        '${date.year % 100}'.padLeft(2, '0') +
        '${date.month}'.padLeft(2, '0') +
        '${date.day}'.padLeft(2, '0');
    final prefix = 'RNZ-$stamp-';
    final existing = _orders()
        .map((order) => order.orderNo)
        .where((number) => number.startsWith(prefix))
        .toSet();
    var sequence = existing.length + 1;
    while (existing.contains('$prefix${sequence.toString().padLeft(4, '0')}')) {
      sequence++;
    }
    return '$prefix${sequence.toString().padLeft(4, '0')}';
  }

  Map<String, dynamic> _addressSnapshot(Address address) {
    return {
      'label': address.label,
      'recipientName': address.recipientName,
      'recipientPhone': address.recipientPhone,
      'province': address.province,
      'city': address.city,
      'district': address.district,
      'addressLine': address.addressLine,
      'postalCode': address.postalCode,
    };
  }

  Map<String, dynamic> _paymentSnapshot(PaymentMethod method) {
    return {
      'type': method.type.name,
      'provider': method.provider,
      'accountNo': method.accountNo,
      'accountName': method.accountName,
    };
  }

  Future<AppResult<void>> _commitTransition({
    required String orderId,
    String? userId,
    required Set<OrderStatus> from,
    required OrderStatus to,
    required String note,
    required ActorType actor,
    required DateTime at,
    bool restoreStock = false,
    Order Function(Order order)? transform,
  }) async {
    final orders = _orders();
    final index = _indexOf(orders, orderId, userId);
    if (index < 0) return _fail('not_found', 'Pesanan tidak ditemukan.');
    final order = orders[index];
    if (!from.contains(order.status)) {
      return _fail('invalid_transition', 'Transisi status tidak valid.');
    }

    var updated = order.copyWith(
      status: to,
      statusLogs: [
        ...order.statusLogs,
        _log(from: order.status, to: to, note: note, actor: actor, at: at),
      ],
    );
    if (transform != null) updated = transform(updated);

    if (restoreStock) {
      final restored = <String, int>{};
      _addStock(restored, order.items);
      await _restoreStock(restored);
    }

    final next = [...orders];
    next[index] = updated;
    await _writeOrders(next);
    return AppResult<void>.ok(null);
  }

  int _indexOf(List<Order> orders, String orderId, String? userId) {
    return orders.indexWhere(
      (order) =>
          order.id == orderId &&
          (userId == null || order.userId == userId),
    );
  }

  StatusLog _log({
    required OrderStatus from,
    required OrderStatus to,
    required String note,
    required ActorType actor,
    required DateTime at,
  }) {
    return StatusLog(
      id: newId('log'),
      fromStatus: from,
      toStatus: to,
      note: note,
      actor: actor,
      createdAt: at,
    );
  }

  List<PaymentProof> _reviewProofs(
    List<PaymentProof> proofs,
    PaymentProofStatus status,
    DateTime at,
    String? reason,
  ) {
    return proofs.map((proof) {
      if (proof.status != PaymentProofStatus.pending) return proof;
      return proof.copyWith(
        status: status,
        reviewedAt: at,
        rejectReason: reason,
      );
    }).toList(growable: false);
  }

  String? _imageMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  void _addStock(Map<String, int> target, List<OrderItem> items) {
    for (final item in items) {
      target.update(
        item.variantId,
        (value) => value + item.qty,
        ifAbsent: () => item.qty,
      );
    }
  }

  Future<void> _restoreStock(Map<String, int> quantities) async {
    var changed = false;
    final next = _products().map((product) {
      var touched = false;
      final variants = product.variants.map((variant) {
        final qty = quantities[variant.id];
        if (qty == null) return variant;
        touched = true;
        return variant.copyWith(stock: variant.stock + qty);
      }).toList(growable: false);
      if (!touched) return product;
      changed = true;
      return product.copyWith(variants: variants);
    }).toList(growable: false);
    if (changed) await _writeProducts(next);
  }

  List<Product> _products() {
    return _store
        .list('products')
        .map((raw) => Product.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeProducts(List<Product> products) {
    return _store.write(
      'products',
      products.map((product) => product.toJson()).toList(growable: false),
    );
  }

  List<Order> _orders() {
    return _store
        .list('orders')
        .map((raw) => Order.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList(growable: false);
  }

  Future<void> _writeOrders(List<Order> orders) {
    return _store.write(
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
