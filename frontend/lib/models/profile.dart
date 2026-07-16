class Profile {
  final String userId;
  final int roleNumber;
  final String fullName;
  final String phone;
  final String status;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? address;

  Profile({
    required this.userId,
    required this.roleNumber,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.avatarUrl,
    this.address,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String? ?? '',
      roleNumber: json['role_number'] as int? ?? 3,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role_number': roleNumber,
      'full_name': fullName,
      'phone': phone,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
      'address': address,
    };
  }

  String get roleName {
    switch (roleNumber) {
      case UserRoles.admin:
        return 'Admin';
      case UserRoles.manager:
        return 'Manager';
      case UserRoles.stockController:
        return 'Stock Controller';
      case UserRoles.salesAssociate:
        return 'Sales Associate';
      case UserRoles.cashier:
        return 'Cashier';
      default:
        return 'Unknown';
    }
  }
}

class UserRoles {
  static const int admin = 1;
  static const int manager = 2;
  static const int stockController = 3;
  static const int salesAssociate = 4;
  static const int cashier = 5;
}
