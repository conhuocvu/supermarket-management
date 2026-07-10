class Profile {
  final String userId;
  final int roleNumber;
  final String fullName;
  final String phone;
  final String status;
  final DateTime createdAt;

  Profile({
    required this.userId,
    required this.roleNumber,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.createdAt,
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
    };
  }

  String get roleName {
    switch (roleNumber) {
      case 1:
        return 'Admin';
      case 2:
        return 'Manager';
      case 3:
        return 'Stock Controller';
      default:
        return 'Unknown';
    }
  }
}
