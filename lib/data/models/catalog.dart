class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'isActive': isActive};
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.color,
    this.size,
    this.sku,
    required this.stock,
    this.isActive = true,
  });

  final String id;
  final String productId;
  final String color;
  final String? size;
  final String? sku;
  final int stock;
  final bool isActive;

  String get label {
    final value = size;
    return value == null || value.isEmpty ? color : '$color / $value';
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawProductId = json['productId'] ?? json['product_id'];
    final rawActive = json['isActive'] ?? json['is_active'];
    final rawStock = json['stock'];
    return ProductVariant(
      id: rawId is int ? rawId.toString() : rawId as String,
      productId:
          rawProductId is int ? rawProductId.toString() : rawProductId as String,
      color: (json['color'] ?? '') as String,
      size: json['size'] as String?,
      sku: json['sku'] as String?,
      stock: rawStock is int ? rawStock : int.parse(rawStock.toString()),
      isActive:
          rawActive is bool ? rawActive : (rawActive?.toString() == '1' || rawActive == null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'color': color,
      'size': size,
      'sku': sku,
      'stock': stock,
      'isActive': isActive,
    };
  }

  ProductVariant copyWith({
    String? color,
    String? size,
    String? sku,
    int? stock,
    bool? isActive,
  }) {
    return ProductVariant(
      id: id,
      productId: productId,
      color: color ?? this.color,
      size: size ?? this.size,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.isActive = true,
    this.deletedAt,
    this.images = const [],
    this.variants = const [],
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int price;
  final bool isActive;
  final DateTime? deletedAt;
  final List<String> images;
  final List<ProductVariant> variants;
  final DateTime createdAt;

  int get totalStock {
    return variants
        .where((variant) => variant.isActive)
        .fold(0, (sum, variant) => sum + variant.stock);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawDeleted = json['deletedAt'] ?? json['deleted_at'];
    final rawCreated = json['createdAt'] ?? json['created_at'];
    final rawActive = json['isActive'] ?? json['is_active'];
    return Product(
      id: rawId is int ? rawId.toString() : rawId as String,
      categoryId: (json['categoryId'] ?? json['category_id']).toString(),
      name: json['name'] as String,
      description: (json['description'] ?? '') as String,
      price: json['price'] is int ? json['price'] as int : int.parse(json['price'].toString()),
      isActive: rawActive is bool ? rawActive : (rawActive?.toString() == '1' || rawActive == null),
      deletedAt: rawDeleted == null
          ? null
          : DateTime.parse(rawDeleted as String),
      images: _parseImages(json['images']),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ProductVariant.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      createdAt: rawCreated != null
          ? DateTime.parse(rawCreated as String)
          : DateTime.now(),
    );
  }

  /// Parse images from either a list of strings (seed) or list of URL strings (API)
  static List<String> _parseImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'isActive': isActive,
      'deletedAt': deletedAt?.toIso8601String(),
      'images': images,
      'variants': variants.map((variant) => variant.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? categoryId,
    String? name,
    String? description,
    int? price,
    bool? isActive,
    DateTime? deletedAt,
    List<String>? images,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      createdAt: createdAt,
    );
  }
}

class PagedProducts {
  const PagedProducts({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  final List<Product> items;
  final int total;
  final int page;
  final int perPage;

  bool get hasMore => page * perPage < total;
}
