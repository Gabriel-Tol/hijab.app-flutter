const Object _unset = Object();

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.passwordSalt,
    this.role = 'customer',
    this.status = 'active',
    this.deletedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String passwordSalt;
  final String role;
  final String status;
  final DateTime? deletedAt;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      passwordHash: json['passwordHash'] as String? ?? '',
      passwordSalt: json['passwordSalt'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      status: json['status'] as String? ?? 'active',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'role': role,
      'status': status,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    String? passwordSalt,
    String? role,
    String? status,
    Object? deletedAt = _unset,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      role: role ?? this.role,
      status: status ?? this.status,
      deletedAt: identical(deletedAt, _unset)
          ? this.deletedAt
          : deletedAt as DateTime?,
      createdAt: createdAt,
    );
  }
}
