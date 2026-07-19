class StaffRequest {
  final int requestNumber;
  final String requestType;
  final String? userId;
  final String employeeName;
  final String reason;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? createdDate;
  final DateTime? approvedDate;

  // Clearance specific fields
  final String? productName;
  final double? discountPercentage;
  final String? batchNumber;
  final double? remainingQuantity;
  final double? sellingPrice;
  final double? importPrice;

  const StaffRequest({
    required this.requestNumber,
    required this.requestType,
    required this.userId,
    required this.employeeName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdDate,
    required this.approvedDate,
    this.productName,
    this.discountPercentage,
    this.batchNumber,
    this.remainingQuantity,
    this.sellingPrice,
    this.importPrice,
  });

  factory StaffRequest.fromJson(Map<String, dynamic> json) {
    return StaffRequest(
      requestNumber: _parseInt(json['requestNumber']),
      requestType: (json['requestType'] ?? '').toString(),
      userId: json['userId']?.toString(),
      employeeName: (json['employeeName'] ?? 'Unknown Staff').toString(),
      reason: (json['reason'] ?? '').toString(),
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      status: (json['status'] ?? 'PENDING').toString(),
      createdDate: _parseDateTime(json['createdDate']),
      approvedDate: _parseDateTime(json['approvedDate']),
      productName: json['productName']?.toString(),
      discountPercentage: _parseDouble(json['discountPercentage']),
      batchNumber: json['batchNumber']?.toString(),
      remainingQuantity: _parseDouble(json['remainingQuantity']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      importPrice: _parseDouble(json['importPrice']),
    );
  }

  bool get isLeaveRequest => requestType.toUpperCase() == 'LEAVE';

  bool get isShiftChangeRequest => requestType.toUpperCase() == 'SHIFT_CHANGE';

  bool get isClearanceRequest => requestType.toUpperCase() == 'CLEARANCE';

  bool get isPurchaseRequest => requestType.toUpperCase() == 'PURCHASE';

  String get requestTypeLabel {
    switch (requestType.toUpperCase()) {
      case 'LEAVE':
        return 'Leave';
      case 'SHIFT_CHANGE':
        return 'Shift Change';
      case 'CLEARANCE':
        return 'Discount';
      case 'PURCHASE':
        return 'Purchase';
      default:
        return requestType;
    }
  }

  String get statusLabel {
    if (status.isEmpty) {
      return 'Unknown';
    }

    final normalized = status.toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  int? get totalLeaveDays {
    if (startDate == null || endDate == null) {
      return null;
    }

    return endDate!.difference(startDate!).inDays + 1;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
