class PendingStockIn {
  final int? purchaseRequestNumber;
  final DateTime? createdDate;
  final String? supplierName;
  final int? supplierNumber;
  final num? totalItems;
  final String? unitName;
  final String? status;

  PendingStockIn({
    this.purchaseRequestNumber,
    this.createdDate,
    this.supplierName,
    this.supplierNumber,
    this.totalItems,
    this.unitName,
    this.status,
  });

  factory PendingStockIn.fromJson(Map<String, dynamic> json) {
    return PendingStockIn(
      purchaseRequestNumber: json['purchaseRequestNumber'],
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      supplierName: json['supplierName'],
      supplierNumber: json['supplierNumber'],
      totalItems: json['totalItems'],
      unitName: json['unitName'],
      status: json['status'],
    );
  }
}

class PendingStockOut {
  final int? reportNumber;
  final String? productName;
  final num? quantity;
  final String? unitName;
  final String? location;
  final DateTime? createdAt;

  PendingStockOut({
    this.reportNumber,
    this.productName,
    this.quantity,
    this.unitName,
    this.location,
    this.createdAt,
  });

  factory PendingStockOut.fromJson(Map<String, dynamic> json) {
    return PendingStockOut(
      reportNumber: json['reportNumber'],
      productName: json['productName'],
      quantity: json['quantity'],
      unitName: json['unitName'],
      location: json['location'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class PendingTasks {
  final List<PendingStockIn> pendingStockIns;
  final List<PendingStockOut> pendingStockOuts;

  PendingTasks({
    required this.pendingStockIns,
    required this.pendingStockOuts,
  });

  factory PendingTasks.fromJson(Map<String, dynamic> json) {
    final ins = json['pendingStockIns'] as List? ?? [];
    final outs = json['pendingStockOuts'] as List? ?? [];
    return PendingTasks(
      pendingStockIns: ins.map((item) => PendingStockIn.fromJson(item)).toList(),
      pendingStockOuts: outs.map((item) => PendingStockOut.fromJson(item)).toList(),
    );
  }
}
