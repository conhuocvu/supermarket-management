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

  PurchaseRequestItem({
    required this.productNumber,
    required this.productName,
    required this.sku,
    required this.requestedQuantity,
    required this.importPrice,
    required this.unitName,
    required this.supplierName,
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
  final List<PurchaseRequestItem> items;

  PurchaseRequestDetail({
    required this.purchaseRequestNumber,
    required this.createdBy,
    this.createdDate,
    this.approvedBy,
    this.approvedDate,
    required this.status,
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
      items: rawItems.map((item) => PurchaseRequestItem.fromJson(item)).toList(),
    );
  }
}
