class InventoryProductDetail {
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
  final DateTime? expiryDate;

  // Supplier Info
  final String supplierName;
  final double? importPrice;
  final double? minimumOrderQuantity;

  // Stock History
  final List<StockHistoryItem> stockHistory;

  InventoryProductDetail({
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
    this.expiryDate,
    required this.supplierName,
    this.importPrice,
    this.minimumOrderQuantity,
    required this.stockHistory,
  });

  factory InventoryProductDetail.fromJson(Map<String, dynamic> json) {
    var historyList =
        (json['stockHistory'] as List?)
            ?.map((e) => StockHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return InventoryProductDetail(
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
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      supplierName: json['supplierName'] ?? 'N/A',
      importPrice: (json['importPrice'] as num?)?.toDouble(),
      minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toDouble(),
      stockHistory: historyList,
    );
  }
}

class StockHistoryItem {
  final String date;
  final String action;
  final double quantity;

  StockHistoryItem({
    required this.date,
    required this.action,
    required this.quantity,
  });

  factory StockHistoryItem.fromJson(Map<String, dynamic> json) {
    return StockHistoryItem(
      date: json['date'] ?? '',
      action: json['action'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
