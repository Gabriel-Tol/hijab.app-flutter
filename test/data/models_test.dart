import 'package:flutter_test/flutter_test.dart';
import 'package:rnz_store/data/models/cart.dart';
import 'package:rnz_store/data/models/catalog.dart';
import 'package:rnz_store/data/models/master.dart';
import 'package:rnz_store/data/models/order.dart';

import '../fixtures.dart';

void main() {
  test('product round-trips and sums stock', () {
    final p = sampleProduct();
    final copy = Product.fromJson(p.toJson());
    expect(copy.name, p.name);
    expect(copy.totalStock, 5);
  });

  test('order round-trips nested items and logs', () {
    final o = sampleOrder();
    final copy = Order.fromJson(o.toJson());
    expect(copy.items.single.productName, o.items.single.productName);
    expect(copy.statusLogs.single.toStatus, OrderStatus.awaitingPayment);
    expect(copy.addressSnapshot['recipientName'], 'Nadia Putri');
  });

  test('status labels are Indonesian', () {
    expect(OrderStatus.awaitingPayment.label, 'Menunggu Pembayaran');
    expect(OrderStatus.paymentVerification.label, 'Verifikasi Pembayaran');
    expect(OrderStatus.cancelled.isFinal, isTrue);
    expect(OrderStatus.shipped.isFinal, isFalse);
    expect(() => OrderStatus.fromJson('unknown'), throwsFormatException);
  });

  test('variant label joins color and size', () {
    expect(sampleProduct().variants.first.label, 'Sage / M');
    expect(sampleProduct().variants.last.label, 'Sage');
  });

  test('cart line and paged products compute derived values', () {
    final p = sampleProduct();
    final line = CartLine(product: p, variant: p.variants.first, qty: 2);
    expect(line.lineTotal, 170000);

    final more = PagedProducts(items: [p], total: 21, page: 1, perPage: 20);
    expect(more.hasMore, isTrue);
    final last = PagedProducts(items: [p], total: 20, page: 1, perPage: 20);
    expect(last.hasMore, isFalse);
  });

  test('master data round-trips enums', () {
    const method = PaymentMethod(
      id: 'pm1',
      type: PaymentType.bank,
      provider: 'BCA',
      accountNo: '1234567890',
      accountName: 'RnZ Store',
      isActive: true,
      sortOrder: 1,
    );
    final copy = PaymentMethod.fromJson(method.toJson());
    expect(copy.type, PaymentType.bank);
    expect(copy.provider, 'BCA');

    const rate = ShippingRate(
      id: 'sr1',
      regionName: 'Pontianak',
      cost: 15000,
      isActive: true,
    );
    expect(ShippingRate.fromJson(rate.toJson()).cost, 15000);
  });
}
