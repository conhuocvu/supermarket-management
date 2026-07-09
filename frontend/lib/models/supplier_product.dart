class SupplierProduct {
  final int? id;
  final int productId;
  final String sku;
  final String name;
  final String category;
  final double basePrice;
  final double importPrice;
  final String unit;
  final String imageUrl;
  final bool assigned;

  SupplierProduct({
    this.id,
    required this.productId,
    required this.sku,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.importPrice,
    required this.unit,
    required this.imageUrl,
    required this.assigned,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      id: json['id'] as int?,
      productId: json['productId'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'unit',
      imageUrl: json['imageUrl'] as String? ?? '',
      assigned: json['assigned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'name': name,
      'category': category,
      'basePrice': basePrice,
      'importPrice': importPrice,
      'unit': unit,
      'imageUrl': imageUrl,
      'assigned': assigned,
    };
  }
}
