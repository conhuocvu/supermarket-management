class ProductReport {
  final int reportNumber;
  final String? reportedBy;
  final String reporterName;
  final int productNumber;
  final String productName;
  final String barcode;
  final String categoryName;
  final int? stockInDetailNumber;
  final String reportType;
  final String? issueType;
  final double? quantity;
  final String unitName;
  final String? description;
  final String status;
  final String? createdAt;
  final String? resolvedBy;
  final String? resolverName;
  final String? resolvedAt;
  final double? discountRate;

  ProductReport({
    required this.reportNumber,
    this.reportedBy,
    required this.reporterName,
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.categoryName,
    this.stockInDetailNumber,
    required this.reportType,
    this.issueType,
    this.quantity,
    required this.unitName,
    this.description,
    required this.status,
    this.createdAt,
    this.resolvedBy,
    this.resolverName,
    this.resolvedAt,
    this.discountRate,
  });

  factory ProductReport.fromJson(Map<String, dynamic> json) {
    return ProductReport(
      reportNumber: json['reportNumber'] ?? 0,
      reportedBy: json['reportedBy'],
      reporterName: json['reporterName'] ?? 'Staff User',
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? 'Unknown Product',
      barcode: json['barcode'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      stockInDetailNumber: json['stockInDetailNumber'],
      reportType: json['reportType'] ?? 'INVENTORY_ISSUE',
      issueType: json['issueType'] ?? json['reportType'] ?? 'LOW_STOCK',
      quantity: json['quantity'] != null ? (json['quantity'] as num).toDouble() : null,
      unitName: json['unitName'] ?? 'Pcs',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'],
      resolvedBy: json['resolvedBy'],
      resolverName: json['resolverName'],
      resolvedAt: json['resolvedAt'],
      discountRate: json['discountRate'] != null ? (json['discountRate'] as num).toDouble() : null,
    );
  }
}
