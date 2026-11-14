import 'dart:async';

import '../../core/result.dart';
import '../local_store.dart';
import '../models/cart.dart';
import 'catalog_repository.dart';

class CartRepository {
  CartRepository(this._store, this._catalog);

  final LocalStore _store;
  final CatalogRepository _catalog;

  List<CartLine> lines(String userId) {
    final lines = <CartLine>[];
    for (final item in _items(userId)) {
      if (item.qty < 1) continue;
      final variant = _catalog.variantById(item.variantId);
      if (variant == null) continue;
      final product = _catalog.productById(variant.productId);
      if (product == null) continue;
      lines.add(CartLine(product: product, variant: variant, qty: item.qty));
    }
    return lines;
  }

  List<String> reconcile(String userId) {
    final warnings = <String>[];
    final next = <CartItem>[];
    var changed = false;

    for (final item in _items(userId)) {
      final variant = _catalog.variantById(item.variantId);
      if (variant == null) {
        changed = true;
        continue;
      }
      if (variant.stock <= 0) {
        warnings.add('${variant.label} habis dan dihapus dari keranjang.');
        changed = true;
        continue;
      }
      if (item.qty > variant.stock) {
        warnings.add(
          'Stok ${variant.label} tersisa ${variant.stock}; jumlah disesuaikan.',
        );
        next.add(CartItem(variantId: item.variantId, qty: variant.stock));
        changed = true;
        continue;
      }
      if (item.qty < 1) {
        changed = true;
        continue;
      }
      next.add(item);
    }

    if (changed) _persist(userId, next);
    return warnings;
  }

  AppResult<void> add(String userId, String variantId, {int qty = 1}) {
    final variant = _catalog.variantById(variantId);
    if (variant == null) {
      return _fail('not_found', 'Produk tidak tersedia.');
    }
    if (qty < 1) {
      return _fail('validation', 'Jumlah minimal 1.', {
        variantId: 'Jumlah minimal 1',
      });
    }

    final items = _items(userId);
    final index = items.indexWhere((item) => item.variantId == variantId);
    final nextQty = (index < 0 ? 0 : items[index].qty) + qty;
    if (nextQty > variant.stock) {
      return _fail('insufficient_stock', 'Stok tidak mencukupi.', {
        variantId: 'Stok tersisa ${variant.stock}',
      });
    }

    final next = [...items];
    if (index < 0) {
      next.add(CartItem(variantId: variantId, qty: qty));
    } else {
      next[index] = CartItem(variantId: variantId, qty: nextQty);
    }
    _persist(userId, next);
    return AppResult<void>.ok(null);
  }

  AppResult<void> setQty(String userId, String variantId, int qty) {
    final variant = _catalog.variantById(variantId);
    if (variant == null) {
      return _fail('not_found', 'Produk tidak tersedia.');
    }
    if (qty < 1) {
      return _fail('validation', 'Jumlah minimal 1.', {
        variantId: 'Jumlah minimal 1',
      });
    }
    if (qty > variant.stock) {
      return _fail('insufficient_stock', 'Stok tidak mencukupi.', {
        variantId: 'Stok tersisa ${variant.stock}',
      });
    }

    final items = _items(userId);
    final index = items.indexWhere((item) => item.variantId == variantId);
    if (index < 0) {
      return _fail('not_found', 'Produk tidak ada di keranjang.');
    }
    final next = [...items];
    next[index] = CartItem(variantId: variantId, qty: qty);
    _persist(userId, next);
    return AppResult<void>.ok(null);
  }

  Future<void> remove(String userId, String variantId) {
    final next = _items(userId)
        .where((item) => item.variantId != variantId)
        .toList(growable: false);
    return _write(userId, next);
  }

  Future<void> clear(String userId) => _write(userId, const []);

  int itemCount(String userId) {
    return lines(userId).fold(0, (sum, line) => sum + line.qty);
  }

  int subtotal(String userId) {
    return lines(userId).fold(0, (sum, line) => sum + line.lineTotal);
  }

  List<CartItem> _items(String userId) {
    final raw = _store.map('cart')[userId];
    if (raw is! List) return const [];
    return raw
        .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  // Fire-and-forget is safe here: SharedPreferences updates its read cache
  // synchronously, so the next read already sees this write.
  void _persist(String userId, List<CartItem> items) {
    unawaited(_write(userId, items));
  }

  Future<void> _write(String userId, List<CartItem> items) {
    final carts = _store.map('cart');
    carts[userId] = items.map((item) => item.toJson()).toList(growable: false);
    return _store.write('cart', carts);
  }

  AppResult<void> _fail(
    String code,
    String message, [
    Map<String, String> fields = const {},
  ]) {
    return AppResult<void>.fail(
      AppError(code: code, message: message, fields: fields),
    );
  }
}
