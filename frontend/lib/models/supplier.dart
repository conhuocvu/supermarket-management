class Supplier {
  final int id;
  final String code;
  final String name;
  final String category;
  final String nextDelivery;
  final String status; // Reliable, Warning, Deactivated
  final String contactType;
  final String contactValue;
  final double onTimeDeliveryRate;
  final double averageRating;
  final String notes;
  final String certification;
  final int activeSkus;

  Supplier({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.nextDelivery,
    required this.status,
    required this.contactType,
    required this.contactValue,
    required this.onTimeDeliveryRate,
    required this.averageRating,
    required this.notes,
    required this.certification,
    required this.activeSkus,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      nextDelivery: json['nextDelivery'] as String? ?? '',
      status: json['status'] as String? ?? 'Reliable',
      contactType: json['contactType'] as String? ?? 'email',
      contactValue: json['contactValue'] as String? ?? '',
      onTimeDeliveryRate: (json['onTimeDeliveryRate'] as num?)?.toDouble() ?? 95.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 4.5,
      notes: json['notes'] as String? ?? '',
      certification: json['certification'] as String? ?? '',
      activeSkus: json['activeSkus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'nextDelivery': nextDelivery,
      'status': status,
      'contactType': contactType,
      'contactValue': contactValue,
      'onTimeDeliveryRate': onTimeDeliveryRate,
      'averageRating': averageRating,
      'notes': notes,
      'certification': certification,
      'activeSkus': activeSkus,
    };
  }
}
