import '../core/constants.dart';
import '../core/password_hasher.dart';
import 'local_store.dart';
import 'models/address.dart';
import 'models/catalog.dart';
import 'models/master.dart';
import 'models/order.dart';
import 'models/user.dart';

class SeedData {
  SeedData._();

  static const String demoEmail = 'nadia@rnzstore.id';
  static const String demoPassword = 'Hijab1234';

  static Future<void> run(LocalStore store) async {
    final now = DateTime(2026, 11, 14, 9);
    const userId = 'u-demo';
    final salt = PasswordHasher.newSalt();

    final user = User(
      id: userId,
      name: 'Nadia Putri',
      email: demoEmail,
      phone: '081234567890',
      passwordHash: PasswordHasher.hash(demoPassword, salt),
      passwordSalt: salt,
      createdAt: now.subtract(const Duration(days: 45)),
    );

    const addresses = [
      Address(
        id: 'a1',
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
      ),
      Address(
        id: 'a2',
        userId: userId,
        label: 'Kantor',
        recipientName: 'Nadia Putri',
        recipientPhone: '081234567890',
        province: 'Kalimantan Barat',
        city: 'Kubu Raya',
        district: 'Sungai Kakap',
        addressLine: 'Jl. Raya Kakap No. 88',
        postalCode: '78381',
      ),
    ];

    const categories = [
      Category(id: 'c1', name: 'Hijab Segiempat', slug: 'hijab-segiempat'),
      Category(id: 'c2', name: 'Pashmina', slug: 'pashmina'),
      Category(id: 'c3', name: 'Dalaman', slug: 'dalaman'),
      Category(id: 'c4', name: 'Gamis/Set Koko', slug: 'gamis-set-koko'),
      Category(id: 'c5', name: 'Aksesori', slug: 'aksesori'),
    ];

    final products = _products(now);

    final methods = [
      PaymentMethod(
        id: 'pm-bca',
        type: PaymentType.bank,
        provider: 'BCA',
        accountNo: '1234567890',
        accountName: 'RnZ Store',
        isActive: true,
        sortOrder: 1,
      ),
      PaymentMethod(
        id: 'pm-mandiri',
        type: PaymentType.bank,
        provider: 'Mandiri',
        accountNo: '1370012345678',
        accountName: 'RnZ Store',
        isActive: true,
        sortOrder: 2,
      ),
      PaymentMethod(
        id: 'pm-dana',
        type: PaymentType.ewallet,
        provider: 'DANA',
        accountNo: '081234567890',
        accountName: 'RnZ Store',
        isActive: true,
        sortOrder: 3,
      ),
      PaymentMethod(
        id: 'pm-ovo',
        type: PaymentType.ewallet,
        provider: 'OVO',
        accountNo: '081234567890',
        accountName: 'RnZ Store',
        isActive: false,
        sortOrder: 4,
      ),
    ];

    const rates = [
      ShippingRate(id: 'sr-pontianak', regionName: 'Pontianak', cost: 15000),
      ShippingRate(id: 'sr-kubu', regionName: 'Kubu Raya', cost: 18000),
      ShippingRate(id: 'sr-mempawah', regionName: 'Mempawah', cost: 25000),
      ShippingRate(id: 'sr-singkawang', regionName: 'Singkawang', cost: 30000),
    ];

    final orders = _orders(
      address: addresses.first,
      method: methods.first,
      products: products,
    );

    await store.write('users', [user.toJson()]);
    await store.write(
      'addresses',
      addresses.map((address) => address.toJson()).toList(),
    );
    await store.write(
      'categories',
      categories.map((category) => category.toJson()).toList(),
    );
    await store.write(
      'products',
      products.map((product) => product.toJson()).toList(),
    );
    await store.write('cart', <String, dynamic>{});
    await store.write(
      'orders',
      orders.map((order) => order.toJson()).toList(),
    );
    await store.write(
      'payment_methods',
      methods.map((method) => method.toJson()).toList(),
    );
    await store.write(
      'shipping_rates',
      rates.map((rate) => rate.toJson()).toList(),
    );
  }

  static List<Product> _products(DateTime now) {
    return List<Product>.generate(_seedProducts.length, (index) {
      final spec = _seedProducts[index];
      final id = 'p${(index + 1).toString().padLeft(2, '0')}';
      final variants = <ProductVariant>[];
      var variantIndex = 0;
      for (final color in spec.colors) {
        for (final size in spec.sizes) {
          final stock = spec.stocks == null
              ? 12
              : spec.stocks![variantIndex % spec.stocks!.length];
          variants.add(
            ProductVariant(
              id: '$id-v${variantIndex + 1}',
              productId: id,
              color: color,
              size: size,
              sku: 'RNZ-${id.toUpperCase()}-${variantIndex + 1}',
              stock: stock,
            ),
          );
          variantIndex++;
        }
      }
      final imageCount = (index % 3) + 1;
      return Product(
        id: id,
        categoryId: spec.categoryId,
        name: spec.name,
        description: spec.description,
        price: spec.price,
        isActive: spec.isActive,
        images: List<String>.generate(
          imageCount,
          (offset) => AppAssets
              .productImages[(index + offset) % AppAssets.productImages.length],
        ),
        variants: variants,
        createdAt: now.subtract(Duration(days: _seedProducts.length - index)),
      );
    });
  }

  static List<Order> _orders({
    required Address address,
    required PaymentMethod method,
    required List<Product> products,
  }) {
    Product find(String id) => products.firstWhere((product) => product.id == id);

    final pashmina = find('p06');
    final gamis = find('p14');
    final shippedItem = _item(pashmina, pashmina.variants.first, 1);
    final completedItem = _item(gamis, gamis.variants.first, 1);

    final now = DateTime.now();
    final shippedCreated = now.subtract(const Duration(days: 4));
    final shippedAt = now.subtract(const Duration(days: 2));
    final completedCreated = now.subtract(const Duration(days: 15));
    final completedShippedAt = now.subtract(const Duration(days: 12));

    return [
      Order(
        id: 'demo-shipped',
        orderNo: 'RNZ-261102-0001',
        userId: 'u-demo',
        status: OrderStatus.shipped,
        subtotal: shippedItem.lineTotal,
        shippingCost: 15000,
        total: shippedItem.lineTotal + 15000,
        addressSnapshot: _addressSnapshot(address),
        paymentMethodSnapshot: _paymentSnapshot(method),
        payBefore: shippedCreated.add(const Duration(hours: 24)),
        createdAt: shippedCreated,
        idempotencyKey: 'seed-shipped',
        items: [shippedItem],
        proofs: [
          PaymentProof(
            id: 'proof-shipped',
            storageKey: 'proof.demo-shipped.pr1',
            status: PaymentProofStatus.approved,
            uploadedAt: shippedCreated.add(const Duration(hours: 2)),
            reviewedAt: shippedCreated.add(const Duration(hours: 3)),
          ),
        ],
        statusLogs: [
          _log(
            id: 'log-shipped-1',
            to: OrderStatus.awaitingPayment,
            note: 'Pesanan dibuat',
            actor: ActorType.customer,
            at: shippedCreated,
          ),
          _log(
            id: 'log-shipped-2',
            from: OrderStatus.awaitingPayment,
            to: OrderStatus.paymentVerification,
            note: 'Bukti pembayaran diunggah',
            actor: ActorType.customer,
            at: shippedCreated.add(const Duration(hours: 2)),
          ),
          _log(
            id: 'log-shipped-3',
            from: OrderStatus.paymentVerification,
            to: OrderStatus.processing,
            note: 'Pembayaran diverifikasi',
            actor: ActorType.admin,
            at: shippedCreated.add(const Duration(hours: 3)),
          ),
          _log(
            id: 'log-shipped-4',
            from: OrderStatus.processing,
            to: OrderStatus.shipped,
            note: 'Dikirim dengan JNE',
            actor: ActorType.admin,
            at: shippedAt,
          ),
        ],
        shipment: Shipment(
          courier: 'JNE',
          trackingNo: 'JNE1234567890',
          shippedAt: shippedAt,
        ),
      ),
      Order(
        id: 'demo-completed',
        orderNo: 'RNZ-261025-0001',
        userId: 'u-demo',
        status: OrderStatus.completed,
        subtotal: completedItem.lineTotal,
        shippingCost: 18000,
        total: completedItem.lineTotal + 18000,
        addressSnapshot: _addressSnapshot(address),
        paymentMethodSnapshot: _paymentSnapshot(method),
        payBefore: completedCreated.add(const Duration(hours: 24)),
        createdAt: completedCreated,
        idempotencyKey: 'seed-completed',
        items: [completedItem],
        proofs: [
          PaymentProof(
            id: 'proof-completed',
            storageKey: 'proof.demo-completed.pr1',
            status: PaymentProofStatus.approved,
            uploadedAt: completedCreated.add(const Duration(hours: 2)),
            reviewedAt: completedCreated.add(const Duration(hours: 4)),
          ),
        ],
        statusLogs: [
          _log(
            id: 'log-completed-1',
            to: OrderStatus.awaitingPayment,
            note: 'Pesanan dibuat',
            actor: ActorType.customer,
            at: completedCreated,
          ),
          _log(
            id: 'log-completed-2',
            from: OrderStatus.awaitingPayment,
            to: OrderStatus.paymentVerification,
            note: 'Bukti pembayaran diunggah',
            actor: ActorType.customer,
            at: completedCreated.add(const Duration(hours: 2)),
          ),
          _log(
            id: 'log-completed-3',
            from: OrderStatus.paymentVerification,
            to: OrderStatus.processing,
            note: 'Pembayaran diverifikasi',
            actor: ActorType.admin,
            at: completedCreated.add(const Duration(hours: 4)),
          ),
          _log(
            id: 'log-completed-4',
            from: OrderStatus.processing,
            to: OrderStatus.shipped,
            note: 'Dikirim dengan SiCepat',
            actor: ActorType.admin,
            at: completedShippedAt,
          ),
          _log(
            id: 'log-completed-5',
            from: OrderStatus.shipped,
            to: OrderStatus.completed,
            note: 'Pesanan diterima pelanggan',
            actor: ActorType.customer,
            at: DateTime(2026, 11, 4, 10, 5),
          ),
        ],
        shipment: Shipment(
          courier: 'SiCepat',
          trackingNo: 'SC9876543210',
          shippedAt: completedShippedAt,
        ),
        completedAt: DateTime(2026, 11, 4, 10, 5),
      ),
    ];
  }

  static OrderItem _item(Product product, ProductVariant variant, int qty) {
    return OrderItem(
      productId: product.id,
      variantId: variant.id,
      productName: product.name,
      variantLabel: variant.label,
      unitPrice: product.price,
      qty: qty,
      lineTotal: product.price * qty,
      imageAsset: product.images.first,
    );
  }

  static Map<String, dynamic> _addressSnapshot(Address address) {
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

  static Map<String, dynamic> _paymentSnapshot(PaymentMethod method) {
    return {
      'type': method.type.name,
      'provider': method.provider,
      'accountNo': method.accountNo,
      'accountName': method.accountName,
    };
  }

  static StatusLog _log({
    required String id,
    OrderStatus? from,
    required OrderStatus to,
    required String note,
    required ActorType actor,
    required DateTime at,
  }) {
    return StatusLog(
      id: id,
      fromStatus: from,
      toStatus: to,
      note: note,
      actor: actor,
      createdAt: at,
    );
  }
}

class _SeedProduct {
  const _SeedProduct(
    this.name,
    this.categoryId,
    this.price,
    this.description,
    this.colors, {
    this.sizes = const [null],
    this.stocks,
    this.isActive = true,
  });

  final String name;
  final String categoryId;
  final int price;
  final String description;
  final List<String> colors;
  final List<String?> sizes;
  final List<int>? stocks;
  final bool isActive;
}

const List<_SeedProduct> _seedProducts = [
  _SeedProduct(
    'Hijab Voal Premium Sage',
    'c1',
    89000,
    'Voal premium dengan tekstur halus dan jatuh lembut untuk pemakaian harian.',
    ['Sage', 'Dusty Rose', 'Mocca'],
    stocks: [12, 8, 0],
  ),
  _SeedProduct(
    'Hijab Bergo Instan Ivory',
    'c1',
    75000,
    'Bergo instan yang praktis dipakai, nyaman sepanjang hari.',
    ['Ivory', 'Black'],
    stocks: [10, 6],
  ),
  _SeedProduct(
    'Hijab Segiempat Motif Terracotta',
    'c1',
    95000,
    'Motif terracotta yang hangat dengan bahan adem dan tidak menerawang.',
    ['Terracotta', 'Navy'],
    stocks: [9, 0],
  ),
  _SeedProduct(
    'Hijab Voal Daily Mocca',
    'c1',
    65000,
    'Pilihan warna netral yang mudah dipadukan dengan outfit sehari-hari.',
    ['Mocca', 'Olive', 'Navy'],
    stocks: [15, 11, 7],
  ),
  _SeedProduct(
    'Hijab Segiempat Klasik',
    'c1',
    55000,
    'Hijab klasik dengan bahan lembut; sedang menunggu restock.',
    ['Ivory', 'Black'],
    stocks: [0, 0],
  ),
  _SeedProduct(
    'Pashmina Tenun Sage',
    'c2',
    125000,
    'Pashmina tenun dengan dimensi lebar dan jatuh yang anggun.',
    ['Sage', 'Terracotta'],
    stocks: [6, 4],
  ),
  _SeedProduct(
    'Pashmina Ceruty Dusty Rose',
    'c2',
    99000,
    'Ceruty premium yang ringan dengan warna dusty rose yang lembut.',
    ['Dusty Rose', 'Ivory', 'Mocca'],
    stocks: [8, 5, 0],
  ),
  _SeedProduct(
    'Pashmina Plisket Navy',
    'c2',
    115000,
    'Pashmina plisket dengan lipatan rapi dan warna navy yang tegas.',
    ['Navy', 'Black'],
    stocks: [7, 3],
  ),
  _SeedProduct(
    'Pashmina Linen Olive',
    'c2',
    135000,
    'Linen bertekstur alami, sejuk, dan cocok untuk cuaca tropis.',
    ['Olive', 'Mocca'],
    stocks: [5, 9],
  ),
  _SeedProduct(
    'Pashmina Silk Terracotta',
    'c2',
    159000,
    'Pashmina silk dengan kilau halus untuk acara istimewa.',
    ['Terracotta', 'Dusty Rose'],
    stocks: [4, 6],
  ),
  _SeedProduct(
    'Ciput Rajut Ivory',
    'c3',
    35000,
    'Ciput rajut nyaman dengan bahan stretch yang mengikuti bentuk kepala.',
    ['Ivory', 'Black', 'Mocca'],
    stocks: [20, 18, 14],
  ),
  _SeedProduct(
    'Inner Hijab Jersey Dusty Rose',
    'c3',
    45000,
    'Inner jersey lembut yang menyerap keringat dan tidak licin.',
    ['Dusty Rose', 'Sage'],
    stocks: [12, 0],
  ),
  _SeedProduct(
    'Ciput Instan Navy',
    'c3',
    39000,
    'Ciput instan dengan tali praktis, siap dipakai dalam hitungan detik.',
    ['Navy', 'Black'],
    stocks: [16, 11],
  ),
  _SeedProduct(
    'Gamis Linen Sage',
    'c4',
    285000,
    'Gamis linen dengan potongan longgar, nyaman untuk acara maupun harian.',
    ['Sage', 'Navy'],
    sizes: ['S', 'M', 'L'],
    stocks: [4, 6, 3, 5, 2, 0],
  ),
  _SeedProduct(
    'Gamis Rayon Mocca',
    'c4',
    265000,
    'Rayon jatuh dengan warna mocca hangat dan detail kancing tersembunyi.',
    ['Mocca', 'Black'],
    sizes: ['M', 'L'],
    stocks: [5, 3, 0, 4],
  ),
  _SeedProduct(
    'Set Koko Linen Terracotta',
    'c4',
    325000,
    'Set koko linen dengan potongan rapi untuk tampilan formal yang tenang.',
    ['Terracotta', 'Ivory'],
    sizes: ['M', 'L', 'XL'],
    stocks: [3, 2, 1, 4, 0, 2],
  ),
  _SeedProduct(
    'Gamis Ceruty Dusty Rose',
    'c4',
    295000,
    'Gamis ceruty bertekstur lembut dengan warna dusty rose yang elegan.',
    ['Dusty Rose', 'Olive'],
    sizes: ['S', 'M', 'L'],
    stocks: [2, 5, 4, 0, 3, 2],
  ),
  _SeedProduct(
    'Scarf Organza Terracotta',
    'c5',
    59000,
    'Scarf organza ringan untuk melengkapi hijab dengan sentuhan warna.',
    ['Terracotta', 'Sage'],
    stocks: [9, 7],
  ),
  _SeedProduct(
    'Bros Kerang Ivory',
    'c5',
    49000,
    'Bros kerang dengan detail sederhana, ringan, dan tidak mudah lepas.',
    ['Ivory', 'Gold'],
    stocks: [12, 0],
  ),
  _SeedProduct(
    'Pashmina Ring Scarf Mocca',
    'c5',
    69000,
    'Ring scarf praktis dengan warna mocca yang cocok untuk bepergian.',
    ['Mocca', 'Navy'],
    stocks: [8, 6],
  ),
  _SeedProduct(
    'Hijab Voal Klasik Navy',
    'c1',
    45000,
    'Produk lama yang sudah tidak dijual; disimpan untuk arsip katalog.',
    ['Navy', 'Black'],
    stocks: [5, 5],
    isActive: false,
  ),
];
