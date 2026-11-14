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
