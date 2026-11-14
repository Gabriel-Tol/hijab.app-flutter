import 'catalog.dart';

class CartItem {
  const CartItem({required this.variantId, required this.qty});

  final String variantId;
  final int qty;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      variantId: json['variantId'] as String,
      qty: json['qty'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'variantId': variantId, 'qty': qty};
}

class CartLine {
  const CartLine({
    required this.product,
    required this.variant,
    required this.qty,
  });

  final Product product;
  final ProductVariant variant;
  final int qty;

  int get lineTotal => product.price * qty;
}
