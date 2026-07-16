class PurchaseRequestList {
  final int purchaseRequestNumber;
  final String createdBy;
  final String status;
  final DateTime? createdDate;
  final String? approvedBy;
  final DateTime? approvedDate;
  final String supplierName;
  final double totalQuantity;
  final int totalItems;

  PurchaseRequestList({
    required this.purchaseRequestNumber,
    required this.createdBy,
    required this.status,
    this.createdDate,
    this.approvedBy,
    this.approvedDate,
    required this.supplierName,
    required this.totalQuantity,
    required this.totalItems,
  });

  factory PurchaseRequestList.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestList(
      purchaseRequestNumber: json['purchaseRequestNumber'] ?? 0,
      createdBy: json['createdBy'] ?? 'System',
      status: json['status'] ?? 'PENDING',
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      approvedBy: json['approvedBy'],
      approvedDate: json['approvedDate'] != null ? DateTime.parse(json['approvedDate']) : null,
      supplierName: json['supplierName'] ?? 'Various',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class PurchaseRequestItem {
  final int productNumber;
  final String productName;
  final String sku;
  final double requestedQuantity;
  final double importPrice;
  final String unitName;
  final String supplierName;
  final String? reason;
  final String? notes;
  final double? currentStock;
  final double? reorderLevel;

  PurchaseRequestItem({
    required this.productNumber,
    required this.productName,
    required this.sku,
    required this.requestedQuantity,
    required this.importPrice,
    required this.unitName,
    required this.supplierName,
    this.reason,
    this.notes,
    this.currentStock,
    this.reorderLevel,
  });

  factory PurchaseRequestItem.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItem(
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? 'Unknown',
      sku: json['sku'] ?? 'N/A',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toDouble() ?? 0.0,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      unitName: json['unitName'] ?? 'Unit',
      supplierName: json['supplierName'] ?? 'Unknown',
      reason: json['reason'],
      notes: json['notes'],
      currentStock: (json['currentStock'] as num?)?.toDouble(),
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble(),
    );
  }
}

class PurchaseRequestDetail {
  final int purchaseRequestNumber;
  final String createdBy;
  final DateTime? createdDate;
  final String? approvedBy;
  final DateTime? approvedDate;
  final String status;
  final DateTime? expectedDeliveryDate;
  final List<PurchaseRequestItem> items;

  PurchaseRequestDetail({
    required this.purchaseRequestNumber,
    required this.createdBy,
    this.createdDate,
    this.approvedBy,
    this.approvedDate,
    required this.status,
    this.expectedDeliveryDate,
    required this.items,
  });

  factory PurchaseRequestDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PurchaseRequestDetail(
      purchaseRequestNumber: json['purchaseRequestNumber'] ?? 0,
      createdBy: json['createdBy'] ?? 'System',
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      approvedBy: json['approvedBy'],
      approvedDate: json['approvedDate'] != null ? DateTime.parse(json['approvedDate']) : null,
      status: json['status'] ?? 'PENDING',
      expectedDeliveryDate: json['expectedDeliveryDate'] != null ? DateTime.parse(json['expectedDeliveryDate']) : null,
      items: rawItems.map((item) => PurchaseRequestItem.fromJson(item)).toList(),
    );
  }
}

class PurchaseRequestFormData {
  final List<SupplierFormData> suppliers;
  final List<ProductFormData> products;

  PurchaseRequestFormData({
    required this.suppliers,
    required this.products,
  });

  factory PurchaseRequestFormData.fromJson(Map<String, dynamic> json) {
    final listSuppliers = json['suppliers'] as List? ?? [];
    final listProducts = json['products'] as List? ?? [];
    return PurchaseRequestFormData(
      suppliers: listSuppliers.map((item) => SupplierFormData.fromJson(item)).toList(),
      products: listProducts.map((item) => ProductFormData.fromJson(item)).toList(),
    );
  }
}

class SupplierFormData {
  final int supplierNumber;
  final String supplierName;

  SupplierFormData({
    required this.supplierNumber,
    required this.supplierName,
  });

  factory SupplierFormData.fromJson(Map<String, dynamic> json) {
    return SupplierFormData(
      supplierNumber: json['supplierNumber'] ?? 0,
      supplierName: json['supplierName'] ?? '',
    );
  }
}

class ProductFormData {
  final int productNumber;
  final String productName;
  final String barcode;
  final String unitName;
  final double currentStock;
  final double reorderLevel;
  final List<ProductSupplierInfo> suppliers;

  ProductFormData({
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.unitName,
    required this.currentStock,
    required this.reorderLevel,
    required this.suppliers,
  });

  factory ProductFormData.fromJson(Map<String, dynamic> json) {
    final listSuppliers = json['suppliers'] as List? ?? [];
    return ProductFormData(
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      unitName: json['unitName'] ?? 'Unit',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      suppliers: listSuppliers.map((item) => ProductSupplierInfo.fromJson(item)).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductFormData &&
          runtimeType == other.runtimeType &&
          productNumber == other.productNumber;

  @override
  int get hashCode => productNumber.hashCode;
}

class ProductSupplierInfo {
  final int supplierNumber;
  final String supplierName;
  final double importPrice;
  final double minimumOrderQuantity;

  ProductSupplierInfo({
    required this.supplierNumber,
    required this.supplierName,
    required this.importPrice,
    required this.minimumOrderQuantity,
  });

  factory ProductSupplierInfo.fromJson(Map<String, dynamic> json) {
    return ProductSupplierInfo(
      supplierNumber: json['supplierNumber'] ?? 0,
      supplierName: json['supplierName'] ?? '',
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSupplierInfo &&
          runtimeType == other.runtimeType &&
          supplierNumber == other.supplierNumber;

  @override
  int get hashCode => supplierNumber.hashCode;
}
