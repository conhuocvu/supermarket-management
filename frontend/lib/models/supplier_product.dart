class SupplierProduct {
  final int productNumber;
  final String productName;
  final String? barcode;
  final String? categoryName;
  final String? unitName;
  final double sellingPrice;
  final String status;
  final String? imageUrl;
  final double? importPrice;
  final double? minimumOrderQuantity;

  SupplierProduct({
    required this.productNumber,
    required this.productName,
    this.barcode,
    this.categoryName,
    this.unitName,
    required this.sellingPrice,
    required this.status,
    this.imageUrl,
    this.importPrice,
    this.minimumOrderQuantity,
  });

  factory SupplierProduct.fromJson(Map<String, dynamic> json) {
    return SupplierProduct(
      productNumber: (json['productNumber'] as num).toInt(),
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      categoryName: json['categoryName'],
      unitName: json['unitName'],
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'ACTIVE',
      imageUrl: json['imageUrl'],
      importPrice: (json['importPrice'] as num?)?.toDouble(),
      minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productNumber': productNumber,
      'productName': productName,
      'barcode': barcode,
      'categoryName': categoryName,
      'unitName': unitName,
      'sellingPrice': sellingPrice,
      'status': status,
      'imageUrl': imageUrl,
      'importPrice': importPrice,
      'minimumOrderQuantity': minimumOrderQuantity,
    };
  }
}
