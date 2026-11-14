class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.recipientName,
    required this.recipientPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.addressLine,
    required this.postalCode,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String label;
  final String recipientName;
  final String recipientPhone;
  final String province;
  final String city;
  final String district;
  final String addressLine;
  final String postalCode;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['userId'] as String,
      label: json['label'] as String,
      recipientName: json['recipientName'] as String,
      recipientPhone: json['recipientPhone'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      district: json['district'] as String,
      addressLine: json['addressLine'] as String,
      postalCode: json['postalCode'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'province': province,
      'city': city,
      'district': district,
      'addressLine': addressLine,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? label,
    String? recipientName,
    String? recipientPhone,
    String? province,
    String? city,
    String? district,
    String? addressLine,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      userId: userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressDraft {
  const AddressDraft({
    required this.label,
    required this.recipientName,
    required this.recipientPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.addressLine,
    required this.postalCode,
  });

  final String label;
  final String recipientName;
  final String recipientPhone;
  final String province;
  final String city;
  final String district;
  final String addressLine;
  final String postalCode;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'province': province,
      'city': city,
      'district': district,
      'addressLine': addressLine,
      'postalCode': postalCode,
    };
  }
}
