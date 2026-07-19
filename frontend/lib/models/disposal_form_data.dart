class DisposalFormData {
  final int stockInDetailNumber;
  final int productNumber;
  final String productName;
  final String barcode;
  final String batchNumber;
  final String? expiryDate;
  final double remainingQuantity;
  final String unitName;
  final double importPrice;
  final double sellingPrice;

  DisposalFormData({
    required this.stockInDetailNumber,
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.batchNumber,
    this.expiryDate,
    required this.remainingQuantity,
    required this.unitName,
    required this.importPrice,
    required this.sellingPrice,
  });

  factory DisposalFormData.fromJson(Map<String, dynamic> json) {
    return DisposalFormData(
      stockInDetailNumber: json['stockInDetailNumber'] ?? 0,
      productNumber: json['productNumber'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      batchNumber: json['batchNumber'] ?? '',
      expiryDate: json['expiryDate'],
      remainingQuantity: (json['remainingQuantity'] ?? 0).toDouble(),
      unitName: json['unitName'] ?? 'Pcs',
      importPrice: (json['importPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
    );
  }
}
