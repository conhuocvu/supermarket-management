class Product {
  final int id;
  final String sku;
  final String name;
  final String category;
  final double basePrice;
  final String unit;
  final String imageUrl;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.basePrice,
    required this.unit,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'unit',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'basePrice': basePrice,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }
}
