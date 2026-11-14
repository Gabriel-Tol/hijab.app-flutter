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
    return ProductVariant(
      id: json['id'] as String,
      productId: json['productId'] as String,
      color: json['color'] as String,
      size: json['size'] as String?,
      sku: json['sku'] as String?,
      stock: json['stock'] as int,
      isActive: json['isActive'] as bool? ?? true,
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
    return Product(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      images: (json['images'] as List<dynamic>? ?? const [])
          .cast<String>(),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ProductVariant.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
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
