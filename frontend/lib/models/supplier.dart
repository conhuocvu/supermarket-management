class Supplier {
  final int? supplierNumber;
  final String supplierName;
  final String? phone;
  final String? email;
  final String status;

  Supplier({
    this.supplierNumber,
    required this.supplierName,
    this.phone,
    this.email,
    required this.status,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierNumber: (json['supplierNumber'] as num?)?.toInt(),
      supplierName: json['supplierName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierNumber': supplierNumber,
      'supplierName': supplierName,
      'phone': phone,
      'email': email,
      'status': status,
    };
  }
}
