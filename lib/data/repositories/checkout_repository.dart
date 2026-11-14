import '../local_store.dart';
import '../models/address.dart';
import '../models/master.dart';
import '../models/order.dart';
import 'cart_repository.dart';
import 'catalog_repository.dart';

class CheckoutRepository {
  CheckoutRepository(this._store, this._cart, CatalogRepository _);

  final LocalStore _store;
  final CartRepository _cart;

  List<PaymentMethod> activePaymentMethods() {
    final methods = _store
        .list('payment_methods')
        .map(
          (raw) => PaymentMethod.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .where((method) => method.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return methods;
  }

  PaymentMethod? paymentMethodById(String id) {
    for (final method in activePaymentMethods()) {
      if (method.id == id) return method;
    }
    return null;
  }

  ShippingRate? rateForCity(String city) {
    final normalized = city.trim().toLowerCase();
    for (final raw in _store.list('shipping_rates')) {
      final rate = ShippingRate.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      if (rate.isActive && rate.regionName.trim().toLowerCase() == normalized) {
        return rate;
      }
    }
    return null;
  }

  CheckoutSummary summary({required String userId, required Address address}) {
    final lines = _cart.lines(userId);
    final subtotal = lines.fold(0, (sum, line) => sum + line.lineTotal);
    final rate = rateForCity(address.city);
    final shippingCost = rate?.cost ?? 0;
    return CheckoutSummary(
      lines: lines,
      subtotal: subtotal,
      shippingCost: shippingCost,
      shippingNote: rate == null ? 'Ongkir dikonfirmasi admin' : null,
      total: subtotal + shippingCost,
    );
  }
}
