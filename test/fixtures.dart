import 'package:rnz_store/data/models/address.dart';
import 'package:rnz_store/data/models/catalog.dart';
import 'package:rnz_store/data/models/order.dart';

final DateTime sampleDate = DateTime(2026, 11, 14, 9);

Product sampleProduct({int sageStock = 2, int mStock = 3}) {
  return Product(
    id: 'p1',
    categoryId: 'c1',
    name: 'Pashmina Sage',
    description: 'Pashmina tenun dengan jatuh lembut.',
    price: 85000,
    images: const ['assets/images/products/rnz_09.jpg'],
    variants: [
      ProductVariant(
        id: 'v1',
        productId: 'p1',
        color: 'Sage',
        size: 'M',
        stock: sageStock,
      ),
      ProductVariant(
        id: 'v2',
        productId: 'p1',
        color: 'Sage',
        stock: mStock,
      ),
    ],
    createdAt: sampleDate,
  );
}

Address sampleAddress({String id = 'a1', String userId = 'u1'}) {
  return Address(
    id: id,
    userId: userId,
    label: 'Rumah',
    recipientName: 'Nadia Putri',
    recipientPhone: '081234567890',
    province: 'Kalimantan Barat',
    city: 'Pontianak',
    district: 'Pontianak Kota',
    addressLine: 'Jl. Gajahmada No. 12',
    postalCode: '78111',
    isDefault: true,
  );
}

Order sampleOrder({OrderStatus status = OrderStatus.awaitingPayment}) {
  return Order(
    id: 'o1',
    orderNo: 'RNZ-261114-0001',
    userId: 'u1',
    status: status,
    subtotal: 170000,
    shippingCost: 15000,
    total: 185000,
    addressSnapshot: const {
      'recipientName': 'Nadia Putri',
      'recipientPhone': '081234567890',
      'city': 'Pontianak',
    },
    paymentMethodSnapshot: const {
      'provider': 'BCA',
      'accountNo': '1234567890',
      'accountName': 'RnZ Store',
    },
    payBefore: sampleDate.add(const Duration(hours: 24)),
    createdAt: sampleDate,
    idempotencyKey: 'k1',
    items: const [
      OrderItem(
        productId: 'p1',
        variantId: 'v1',
        productName: 'Pashmina Sage',
        variantLabel: 'Sage / M',
        unitPrice: 85000,
        qty: 2,
        lineTotal: 170000,
        imageAsset: 'assets/images/products/rnz_09.jpg',
      ),
    ],
    statusLogs: [
      StatusLog(
        id: 'l1',
        toStatus: OrderStatus.awaitingPayment,
        note: 'Pesanan dibuat',
        actor: ActorType.customer,
        createdAt: sampleDate,
      ),
    ],
  );
}
