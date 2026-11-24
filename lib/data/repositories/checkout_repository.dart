import '../api_client.dart';
import '../local_store.dart';
import '../models/address.dart';
import '../models/master.dart';
import '../models/order.dart';
import 'cart_repository.dart';
import 'catalog_repository.dart';

class CheckoutRepository {
  CheckoutRepository(this._store, this._cart, CatalogRepository _, {ApiClient? apiClient})
      : _apiClient = apiClient;

  final LocalStore _store;
  final CartRepository _cart;
  final ApiClient? _apiClient;

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

  /// Fetch payment methods from API with fallback to local store
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final localMethods = activePaymentMethods();

    if (_apiClient == null) {
      return localMethods;
    }

    final result = await _apiClient!.fetchPaymentMethods();
    if (result.isOk && result.value != null) {
      final methods = result.value!
          .map((raw) => PaymentMethod.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ))
          .where((method) => method.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Update local store with fresh data
      await _store.write('payment_methods', result.value!);
      return methods;
    }

    // Fallback to local store on API failure
    return localMethods;
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

  /// Fetch shipping rates from API with fallback to local store
  Future<List<ShippingRate>> fetchShippingRates() async {
    final localRates = _store
        .list('shipping_rates')
        .map((raw) => ShippingRate.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ))
        .where((rate) => rate.isActive)
        .toList();

    if (_apiClient == null) {
      return localRates;
    }

    final result = await _apiClient!.fetchShippingRates();
    if (result.isOk && result.value != null) {
      final rates = result.value!
          .map((raw) => ShippingRate.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ))
          .where((rate) => rate.isActive)
          .toList();

      // Update local store with fresh data
      await _store.write('shipping_rates', result.value!);
      return rates;
    }

    return localRates;
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

  /// Refresh payment methods and shipping rates from API
  /// Updates local store with fresh data from backend
  Future<void> refreshSettings() async {
    if (_apiClient == null) return;

    // Fetch payment methods in background
    await _apiClient!.fetchPaymentMethods().then((result) {
      if (result.isOk && result.value != null) {
        _store.write('payment_methods', result.value!);
      }
    });

    // Fetch shipping rates in background
    await _apiClient!.fetchShippingRates().then((result) {
      if (result.isOk && result.value != null) {
        _store.write('shipping_rates', result.value!);
      }
    });
  }
}
