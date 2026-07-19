class LowStockProduct {
  final int productNumber;
  final String productName;
  final String sku;
  final double currentStock;
  final double reorderLevel;
  final String unitName;
  final double suggestedQuantity;
  final double minOrderQuantity;
  final double importPrice;
  final String suggestion;
  final bool critical;

  LowStockProduct({
    required this.productNumber,
    required this.productName,
    required this.sku,
    required this.currentStock,
    required this.reorderLevel,
    required this.unitName,
    required this.suggestedQuantity,
    required this.minOrderQuantity,
    required this.importPrice,
    required this.suggestion,
    required this.critical,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? 'Unknown',
      sku: json['sku'] ?? 'N/A',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      unitName: json['unitName'] ?? 'Unit',
      suggestedQuantity: (json['suggestedQuantity'] as num?)?.toDouble() ?? 0.0,
      minOrderQuantity: (json['minOrderQuantity'] as num?)?.toDouble() ?? 0.0,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      suggestion: json['suggestion'] ?? '',
      critical: json['critical'] ?? false,
    );
  }
}
