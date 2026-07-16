class InventoryTransaction {
  final int? transactionNumber;
  final int? productNumber;
  final String? productName;
  final String? type;
  final num? quantity;
  final String? unitName;
  final String? referenceType;
  final int? referenceId;
  final String? reason;
  final String? createdBy;
  final DateTime? createdAt;

  InventoryTransaction({
    this.transactionNumber,
    this.productNumber,
    this.productName,
    this.type,
    this.quantity,
    this.unitName,
    this.referenceType,
    this.referenceId,
    this.reason,
    this.createdBy,
    this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      transactionNumber: json['transactionNumber'],
      productNumber: json['productNumber'],
      productName: json['productName'],
      type: json['type'],
      quantity: json['quantity'],
      unitName: json['unitName'],
      referenceType: json['referenceType'],
      referenceId: json['referenceId'],
      reason: json['reason'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
