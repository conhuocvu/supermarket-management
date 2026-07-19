class ExpiringProduct {
  final int stockInDetailNumber;
  final int productNumber;
  final String productName;
  final String barcode;
  final String batchNumber;
  final double quantity;
  final DateTime expiryDate;
  final int daysRemaining;
  final bool critical;
  final int expiryWarningDays;
  final double importPrice;

  ExpiringProduct({
    required this.stockInDetailNumber,
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.batchNumber,
    required this.quantity,
    required this.expiryDate,
    required this.daysRemaining,
    required this.critical,
    required this.expiryWarningDays,
    required this.importPrice,
  });

  factory ExpiringProduct.fromJson(Map<String, dynamic> json) {
    return ExpiringProduct(
      stockInDetailNumber: json['stockInDetailNumber'] ?? 0,
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? 'Unknown',
      barcode: json['barcode'] ?? 'N/A',
      batchNumber: json['batchNumber'] ?? 'N/A',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : DateTime.now(),
      daysRemaining: json['daysRemaining'] ?? 0,
      critical: json['critical'] ?? false,
      expiryWarningDays: json['expiryWarningDays'] ?? 30,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
