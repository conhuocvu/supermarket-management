class InventoryProduct {
  final int productNumber;
  final String productName;
  final String barcode;
  final String categoryName;
  final String unitName;
  final double stock;
  final double sellingPrice;
  final double reorderLevel;
  final String status;
  final String description;
  final String imageUrl;
  final int expiryWarningDays;

  InventoryProduct({
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.categoryName,
    required this.unitName,
    required this.stock,
    required this.sellingPrice,
    required this.reorderLevel,
    required this.status,
    required this.description,
    required this.imageUrl,
    required this.expiryWarningDays,
  });

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    return InventoryProduct(
      productNumber: (json['productNumber'] as num?)?.toInt() ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      categoryName: json['categoryName'] ?? '',
      unitName: json['unitName'] ?? '',
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      expiryWarningDays: (json['expiryWarningDays'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productNumber': productNumber,
      'productName': productName,
      'barcode': barcode,
      'categoryName': categoryName,
      'unitName': unitName,
      'stock': stock,
      'sellingPrice': sellingPrice,
      'reorderLevel': reorderLevel,
      'status': status,
      'description': description,
      'imageUrl': imageUrl,
      'expiryWarningDays': expiryWarningDays,
    };
  }
}
