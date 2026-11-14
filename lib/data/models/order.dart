import 'cart.dart';

const Object _unsetOrder = Object();

enum OrderStatus {
  awaitingPayment('Menunggu Pembayaran'),
  paymentVerification('Verifikasi Pembayaran'),
  processing('Diproses'),
  shipped('Dikirim'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  const OrderStatus(this.label);

  final String label;

  bool get isFinal => this == completed || this == cancelled;

  static OrderStatus fromJson(String value) {
    for (final status in OrderStatus.values) {
      if (status.name == value) return status;
    }
    throw FormatException('Status pesanan tidak dikenal: $value');
  }
}

enum PaymentProofStatus {
  pending('Menunggu Verifikasi'),
  approved('Disetujui'),
  rejected('Ditolak');

  const PaymentProofStatus(this.label);

  final String label;

  static PaymentProofStatus fromJson(String value) {
    for (final status in PaymentProofStatus.values) {
      if (status.name == value) return status;
    }
    throw FormatException('Status bukti tidak dikenal: $value');
  }
}

enum ActorType {
  customer('Pelanggan'),
  admin('Admin'),
  system('Sistem');

  const ActorType(this.label);

  final String label;

  static ActorType fromJson(String value) {
    for (final actor in ActorType.values) {
      if (actor.name == value) return actor;
    }
    throw FormatException('Aktor tidak dikenal: $value');
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.imageAsset,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String variantLabel;
  final int unitPrice;
  final int qty;
  final int lineTotal;
  final String imageAsset;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      variantId: json['variantId'] as String,
      productName: json['productName'] as String,
      variantLabel: json['variantLabel'] as String,
      unitPrice: json['unitPrice'] as int,
      qty: json['qty'] as int,
      lineTotal: json['lineTotal'] as int,
      imageAsset: json['imageAsset'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantLabel': variantLabel,
      'unitPrice': unitPrice,
      'qty': qty,
      'lineTotal': lineTotal,
      'imageAsset': imageAsset,
    };
  }
}

class PaymentProof {
  const PaymentProof({
    required this.id,
    required this.storageKey,
    required this.status,
    required this.uploadedAt,
    this.reviewedAt,
    this.rejectReason,
  });

  final String id;
  final String storageKey;
  final PaymentProofStatus status;
  final DateTime uploadedAt;
  final DateTime? reviewedAt;
  final String? rejectReason;

  factory PaymentProof.fromJson(Map<String, dynamic> json) {
    return PaymentProof(
      id: json['id'] as String,
      storageKey: json['storageKey'] as String,
      status: PaymentProofStatus.fromJson(json['status'] as String),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      rejectReason: json['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storageKey': storageKey,
      'status': status.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'rejectReason': rejectReason,
    };
  }

  PaymentProof copyWith({
    PaymentProofStatus? status,
    DateTime? reviewedAt,
    String? rejectReason,
  }) {
    return PaymentProof(
      id: id,
      storageKey: storageKey,
      status: status ?? this.status,
      uploadedAt: uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}

class Shipment {
  const Shipment({
    required this.courier,
    required this.trackingNo,
    required this.shippedAt,
  });

  final String courier;
  final String trackingNo;
  final DateTime shippedAt;

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      courier: json['courier'] as String,
      trackingNo: json['trackingNo'] as String,
      shippedAt: DateTime.parse(json['shippedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courier': courier,
      'trackingNo': trackingNo,
      'shippedAt': shippedAt.toIso8601String(),
    };
  }
}

class StatusLog {
  const StatusLog({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.note,
    required this.actor,
    required this.createdAt,
  });

  final String id;
  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final String? note;
  final ActorType actor;
  final DateTime createdAt;

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: json['id'] as String,
      fromStatus: json['fromStatus'] == null
          ? null
          : OrderStatus.fromJson(json['fromStatus'] as String),
      toStatus: OrderStatus.fromJson(json['toStatus'] as String),
      note: json['note'] as String?,
      actor: ActorType.fromJson(json['actor'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromStatus': fromStatus?.name,
      'toStatus': toStatus.name,
      'note': note,
      'actor': actor.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNo,
    required this.userId,
    required this.status,
    required this.subtotal,
    required this.shippingCost,
    this.shippingNote,
    required this.total,
    required this.addressSnapshot,
    required this.paymentMethodSnapshot,
    required this.payBefore,
    required this.createdAt,
    required this.idempotencyKey,
    this.items = const [],
    this.proofs = const [],
    this.statusLogs = const [],
    this.shipment,
    this.latestRejectReason,
    this.completedAt,
  });

  final String id;
  final String orderNo;
  final String userId;
  final OrderStatus status;
  final int subtotal;
  final int shippingCost;
  final String? shippingNote;
  final int total;
  final Map<String, dynamic> addressSnapshot;
  final Map<String, dynamic> paymentMethodSnapshot;
  final DateTime payBefore;
  final DateTime createdAt;
  final String idempotencyKey;
  final List<OrderItem> items;
  final List<PaymentProof> proofs;
  final List<StatusLog> statusLogs;
  final Shipment? shipment;
  final String? latestRejectReason;
  final DateTime? completedAt;

  DateTime? get shippedAt => shipment?.shippedAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    final shipment = json['shipment'];
    return Order(
      id: json['id'] as String,
      orderNo: json['orderNo'] as String,
      userId: json['userId'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      subtotal: json['subtotal'] as int,
      shippingCost: json['shippingCost'] as int,
      shippingNote: json['shippingNote'] as String?,
      total: json['total'] as int,
      addressSnapshot: Map<String, dynamic>.from(
        json['addressSnapshot'] as Map? ?? const {},
      ),
      paymentMethodSnapshot: Map<String, dynamic>.from(
        json['paymentMethodSnapshot'] as Map? ?? const {},
      ),
      payBefore: DateTime.parse(json['payBefore'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      idempotencyKey: json['idempotencyKey'] as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      proofs: (json['proofs'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                PaymentProof.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      statusLogs: (json['statusLogs'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                StatusLog.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      shipment: shipment == null
          ? null
          : Shipment.fromJson(Map<String, dynamic>.from(shipment as Map)),
      latestRejectReason: json['latestRejectReason'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'userId': userId,
      'status': status.name,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'shippingNote': shippingNote,
      'total': total,
      'addressSnapshot': addressSnapshot,
      'paymentMethodSnapshot': paymentMethodSnapshot,
      'payBefore': payBefore.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'idempotencyKey': idempotencyKey,
      'items': items.map((item) => item.toJson()).toList(),
      'proofs': proofs.map((proof) => proof.toJson()).toList(),
      'statusLogs': statusLogs.map((log) => log.toJson()).toList(),
      'shipment': shipment?.toJson(),
      'latestRejectReason': latestRejectReason,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Order copyWith({
    OrderStatus? status,
    List<PaymentProof>? proofs,
    List<StatusLog>? statusLogs,
    Object? shipment = _unsetOrder,
    Object? latestRejectReason = _unsetOrder,
    Object? completedAt = _unsetOrder,
  }) {
    return Order(
      id: id,
      orderNo: orderNo,
      userId: userId,
      status: status ?? this.status,
      subtotal: subtotal,
      shippingCost: shippingCost,
      shippingNote: shippingNote,
      total: total,
      addressSnapshot: addressSnapshot,
      paymentMethodSnapshot: paymentMethodSnapshot,
      payBefore: payBefore,
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
      items: items,
      proofs: proofs ?? this.proofs,
      statusLogs: statusLogs ?? this.statusLogs,
      shipment: identical(shipment, _unsetOrder)
          ? this.shipment
          : shipment as Shipment?,
      latestRejectReason: identical(latestRejectReason, _unsetOrder)
          ? this.latestRejectReason
          : latestRejectReason as String?,
      completedAt: identical(completedAt, _unsetOrder)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}

class CheckoutSummary {
  const CheckoutSummary({
    required this.lines,
    required this.subtotal,
    required this.shippingCost,
    this.shippingNote,
    required this.total,
  });

  final List<CartLine> lines;
  final int subtotal;
  final int shippingCost;
  final String? shippingNote;
  final int total;
}
