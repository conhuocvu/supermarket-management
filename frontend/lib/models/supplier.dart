class Supplier {
  final int? supplierNumber;
  final String supplierName;
  final String? phone;
  final String? email;
  final String status;
  final String? contactPerson;
  final String? address;
  final String? category;
  final String? notes;

  Supplier({
    this.supplierNumber,
    required this.supplierName,
    this.phone,
    this.email,
    required this.status,
    this.contactPerson,
    this.address,
    this.category,
    this.notes,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      supplierNumber: (json['supplierNumber'] as num?)?.toInt(),
      supplierName: json['supplierName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      status: json['status'] ?? 'ACTIVE',
      contactPerson: json['contactPerson'],
      address: json['address'],
      category: json['category'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierNumber': supplierNumber,
      'supplierName': supplierName,
      'phone': phone,
      'email': email,
      'status': status,
      'contactPerson': contactPerson,
      'address': address,
      'category': category,
      'notes': notes,
    };
  }
}
