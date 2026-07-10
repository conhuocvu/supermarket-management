class ProductAdjustmentData {
  final int productNumber;
  final String productName;
  final String barcode;
  final String unitName;
  final double availableQuantity;

  ProductAdjustmentData({
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.unitName,
    required this.availableQuantity,
  });

  factory ProductAdjustmentData.fromJson(Map<String, dynamic> json) {
    return ProductAdjustmentData(
      productNumber: (json['productNumber'] as num?)?.toInt() ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      unitName: json['unitName'] ?? 'Unit',
      availableQuantity: (json['availableQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
