class CashierShift {
  final String name;
  final DateTime? startDateTime;
  final DateTime? endDateTime;

  const CashierShift({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
  });

  factory CashierShift.fromJson(Map<String, dynamic> json) => CashierShift(
        name: (json['name'] ?? 'Today').toString(),
        startDateTime: _date(json['startDateTime']),
        endDateTime: _date(json['endDateTime']),
      );
}

class CashierInvoiceSummary {
  final int invoiceNumber;
  final String customerName;
  final double totalAmount;
  final double finalAmount;
  final String status;
  final String? paymentMethod;
  final DateTime? createdDate;

  const CashierInvoiceSummary({
    required this.invoiceNumber,
    required this.customerName,
    required this.totalAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdDate,
  });

  factory CashierInvoiceSummary.fromJson(Map<String, dynamic> json) =>
      CashierInvoiceSummary(
        invoiceNumber: _int(json['invoiceNumber']),
        customerName: (json['customerName'] ?? 'Walk-in Customer').toString(),
        totalAmount: _double(json['totalAmount']),
        finalAmount: _double(json['finalAmount']),
        status: (json['status'] ?? '').toString(),
        paymentMethod: json['paymentMethod']?.toString(),
        createdDate: _utcDate(json['createdDate']),
      );
}

class CashierDashboardData {
  final int invoiceCount;
  final double revenue;
  final int unpaidInvoiceCount;
  final CashierShift currentShift;
  final List<CashierInvoiceSummary> recentInvoices;
  final List<String> alerts;

  const CashierDashboardData({
    required this.invoiceCount,
    required this.revenue,
    required this.unpaidInvoiceCount,
    required this.currentShift,
    required this.recentInvoices,
    required this.alerts,
  });

  factory CashierDashboardData.fromJson(Map<String, dynamic> json) =>
      CashierDashboardData(
        invoiceCount: _int(json['invoiceCount']),
        revenue: _double(json['revenue']),
        unpaidInvoiceCount: _int(json['unpaidInvoiceCount']),
        currentShift: CashierShift.fromJson(_map(json['currentShift'])),
        recentInvoices: (json['recentInvoices'] as List? ?? [])
            .whereType<Map>()
            .map((e) => CashierInvoiceSummary.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(),
        alerts: (json['alerts'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class CashierCategory {
  final int categoryNumber;
  final String categoryName;

  const CashierCategory({
    required this.categoryNumber,
    required this.categoryName,
  });

  factory CashierCategory.fromJson(Map<String, dynamic> json) => CashierCategory(
        categoryNumber: _int(json['categoryNumber']),
        categoryName: (json['categoryName'] ?? '').toString(),
      );
}

class CashierProduct {
  final int productNumber;
  final int? categoryNumber;
  final String categoryName;
  final String productName;
  final String barcode;
  final double sellingPrice;
  final double availableQuantity;
  final String? imageUrl;
  final bool expired;

  const CashierProduct({
    required this.productNumber,
    required this.categoryNumber,
    required this.categoryName,
    required this.productName,
    required this.barcode,
    required this.sellingPrice,
    required this.availableQuantity,
    required this.imageUrl,
    required this.expired,
  });

  factory CashierProduct.fromJson(Map<String, dynamic> json) => CashierProduct(
        productNumber: _int(json['productNumber']),
        categoryNumber: _nullableInt(json['categoryNumber']),
        categoryName: (json['categoryName'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        barcode: (json['barcode'] ?? '').toString(),
        sellingPrice: _double(json['sellingPrice']),
        availableQuantity: _double(json['availableQuantity']),
        imageUrl: json['imageUrl']?.toString(),
        expired: json['expired'] == true,
      );

  bool get canSell => !expired && availableQuantity > 0;
}

class CashierCustomer {
  final int customerNumber;
  final String fullName;
  final String phone;
  final int point;

  const CashierCustomer({
    required this.customerNumber,
    required this.fullName,
    required this.phone,
    required this.point,
  });

  factory CashierCustomer.fromJson(Map<String, dynamic> json) => CashierCustomer(
        customerNumber: _int(json['customerNumber']),
        fullName: (json['fullName'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        point: _int(json['point']),
      );
}

class CashierPromotion {
  final int? promotionNumber;
  final String promotionName;
  final double discountPercent;
  final double eligibleAmount;
  final double discountAmount;

  const CashierPromotion({
    required this.promotionNumber,
    required this.promotionName,
    required this.discountPercent,
    required this.eligibleAmount,
    required this.discountAmount,
  });

  factory CashierPromotion.fromJson(Map<String, dynamic> json) => CashierPromotion(
        promotionNumber: _nullableInt(json['promotionNumber']),
        promotionName: (json['promotionName'] ?? '').toString(),
        discountPercent: _double(json['discountPercent']),
        eligibleAmount: _double(json['eligibleAmount']),
        discountAmount: _double(json['discountAmount']),
      );
}

class CashierInvoiceLine {
  final int invoiceDetailNumber;
  final int productNumber;
  final String productName;
  final String barcode;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? imageUrl;

  const CashierInvoiceLine({
    required this.invoiceDetailNumber,
    required this.productNumber,
    required this.productName,
    required this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.imageUrl,
  });

  factory CashierInvoiceLine.fromJson(Map<String, dynamic> json) =>
      CashierInvoiceLine(
        invoiceDetailNumber: _int(json['invoiceDetailNumber']),
        productNumber: _int(json['productNumber']),
        productName: (json['productName'] ?? '').toString(),
        barcode: (json['barcode'] ?? '').toString(),
        quantity: _double(json['quantity']),
        unitPrice: _double(json['unitPrice']),
        lineTotal: _double(json['lineTotal']),
        imageUrl: json['imageUrl']?.toString(),
      );
}

class CashierInvoice {
  final int invoiceNumber;
  final String? cashierId;
  final String cashierName;
  final CashierCustomer? customer;
  final double totalAmount;
  final double finalAmount;
  final String status;
  final DateTime? createdDate;
  final String? paymentMethod;
  final double paidAmount;
  final List<CashierInvoiceLine> items;

  const CashierInvoice({
    required this.invoiceNumber,
    required this.cashierId,
    required this.cashierName,
    required this.customer,
    required this.totalAmount,
    required this.finalAmount,
    required this.status,
    required this.createdDate,
    required this.paymentMethod,
    required this.paidAmount,
    required this.items,
  });

  factory CashierInvoice.fromJson(Map<String, dynamic> json) => CashierInvoice(
        invoiceNumber: _int(json['invoiceNumber']),
        cashierId: json['cashierId']?.toString(),
        cashierName: (json['cashierName'] ?? 'Cashier').toString(),
        customer: json['customer'] is Map
            ? CashierCustomer.fromJson(_map(json['customer']))
            : null,
        totalAmount: _double(json['totalAmount']),
        finalAmount: _double(json['finalAmount']),
        status: (json['status'] ?? '').toString(),
        createdDate: _utcDate(json['createdDate']),
        paymentMethod: json['paymentMethod']?.toString(),
        paidAmount: _double(json['paidAmount']),
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => CashierInvoiceLine.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(),
      );

  bool get isUnpaid => status.toUpperCase() == 'UNPAID';
  bool get isPaid => status.toUpperCase() == 'PAID';
}

class CheckoutPreview {
  final CashierInvoice invoice;
  final CashierPromotion? promotion;
  final int rewardPointsUsed;
  final double rewardDiscount;
  final double finalAmount;
  final int availableCustomerPoints;
  final int estimatedPointsEarned;

  const CheckoutPreview({
    required this.invoice,
    required this.promotion,
    required this.rewardPointsUsed,
    required this.rewardDiscount,
    required this.finalAmount,
    required this.availableCustomerPoints,
    required this.estimatedPointsEarned,
  });

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) => CheckoutPreview(
        invoice: CashierInvoice.fromJson(_map(json['invoice'])),
        promotion: json['promotion'] is Map
            ? CashierPromotion.fromJson(_map(json['promotion']))
            : null,
        rewardPointsUsed: _int(json['rewardPointsUsed']),
        rewardDiscount: _double(json['rewardDiscount']),
        finalAmount: _double(json['finalAmount']),
        availableCustomerPoints: _int(json['availableCustomerPoints']),
        estimatedPointsEarned: _int(json['estimatedPointsEarned']),
      );
}

class CashierReceipt {
  final CashierInvoice invoice;
  final CashierPromotion? promotion;
  final int rewardPointsUsed;
  final double rewardDiscount;
  final int pointsEarned;
  final double paidAmount;
  final double changeAmount;
  final DateTime? paymentDate;

  const CashierReceipt({
    required this.invoice,
    required this.promotion,
    required this.rewardPointsUsed,
    required this.rewardDiscount,
    required this.pointsEarned,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentDate,
  });

  factory CashierReceipt.fromJson(Map<String, dynamic> json) => CashierReceipt(
        invoice: CashierInvoice.fromJson(_map(json['invoice'])),
        promotion: json['promotion'] is Map
            ? CashierPromotion.fromJson(_map(json['promotion']))
            : null,
        rewardPointsUsed: _int(json['rewardPointsUsed']),
        rewardDiscount: _double(json['rewardDiscount']),
        pointsEarned: _int(json['pointsEarned']),
        paidAmount: _double(json['paidAmount']),
        changeAmount: _double(json['changeAmount']),
        paymentDate: _utcDate(json['paymentDate']),
      );
}

class ShiftInvoicePage {
  final List<CashierInvoiceSummary> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;
  final CashierShift shift;

  const ShiftInvoicePage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalItems,
    required this.totalPages,
    required this.shift,
  });

  factory ShiftInvoicePage.fromJson(Map<String, dynamic> json) => ShiftInvoicePage(
        items: (json['items'] as List? ?? [])
            .whereType<Map>()
            .map((e) => CashierInvoiceSummary.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(),
        page: _int(json['page']),
        size: _int(json['size'], fallback: 10),
        totalItems: _int(json['totalItems']),
        totalPages: _int(json['totalPages']),
        shift: CashierShift.fromJson(_map(json['shift'])),
      );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _int(dynamic value, {int fallback = 0}) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  return value is int ? value : int.tryParse(value.toString());
}

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _date(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _utcDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null || parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
