enum PaymentType {
  bank('Transfer Bank'),
  ewallet('E-Wallet');

  const PaymentType(this.label);

  final String label;

  static PaymentType fromJson(String value) {
    for (final type in PaymentType.values) {
      if (type.name == value) return type;
    }
    throw FormatException('Tipe pembayaran tidak dikenal: $value');
  }
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.provider,
    required this.accountNo,
    required this.accountName,
    this.isActive = true,
    required this.sortOrder,
  });

  final String id;
  final PaymentType type;
  final String provider;
  final String accountNo;
  final String accountName;
  final bool isActive;
  final int sortOrder;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentType.fromJson(json['type'] as String),
      provider: json['provider'] as String,
      accountNo: json['accountNo'] as String,
      accountName: json['accountName'] as String,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'provider': provider,
      'accountNo': accountNo,
      'accountName': accountName,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}

class ShippingRate {
  const ShippingRate({
    required this.id,
    required this.regionName,
    required this.cost,
    this.isActive = true,
  });

  final String id;
  final String regionName;
  final int cost;
  final bool isActive;

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      id: json['id'] as String,
      regionName: json['regionName'] as String,
      cost: json['cost'] as int,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regionName': regionName,
      'cost': cost,
      'isActive': isActive,
    };
  }
}
