// Models for the Sales Associate workspace (product list, issue reports,
// update suggestions). Backed by mock data until the sales API is wired up.

enum SalesRequestType { leave, shiftSwap, productSuggestion, inventoryIssue }

enum SalesRequestStatus { pending, approved, rejected, resolved }

class SalesProduct {
  final String sku;
  final String name;
  final String category;
  final double costPrice;
  final double retailPrice;
  final int stockCount;
  final int minStockLevel;
  final int shelfCapacity;
  final String aisle;
  final String shelf;
  final String supplier;
  final String barcode;
  final List<String> history;
  final String? imageUrl;

  const SalesProduct({
    required this.sku,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.retailPrice,
    required this.stockCount,
    required this.minStockLevel,
    required this.shelfCapacity,
    required this.aisle,
    required this.shelf,
    required this.supplier,
    required this.barcode,
    required this.history,
    this.imageUrl,
  });

  String get stockStatus {
    if (stockCount == 0) return 'Out of Stock';
    if (stockCount <= minStockLevel) return 'Low Stock';
    return 'In Stock';
  }

  SalesProduct copyWith({
    String? sku,
    String? name,
    String? category,
    double? costPrice,
    double? retailPrice,
    int? stockCount,
    int? minStockLevel,
    int? shelfCapacity,
    String? aisle,
    String? shelf,
    String? supplier,
    String? barcode,
    List<String>? history,
    String? imageUrl,
  }) {
    return SalesProduct(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stockCount: stockCount ?? this.stockCount,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      shelfCapacity: shelfCapacity ?? this.shelfCapacity,
      aisle: aisle ?? this.aisle,
      shelf: shelf ?? this.shelf,
      supplier: supplier ?? this.supplier,
      barcode: barcode ?? this.barcode,
      history: history ?? this.history,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class SalesTimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  const SalesTimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    this.isCompleted = true,
  });
}

class SalesRequestItem {
  final String id;
  final SalesRequestType type;
  final String title;
  final String description;
  final SalesRequestStatus status;
  final DateTime submissionDate;
  final List<SalesTimelineEvent> timeline;
  final Map<String, dynamic> details;

  const SalesRequestItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.submissionDate,
    required this.timeline,
    required this.details,
  });

  SalesRequestItem copyWith({
    String? id,
    SalesRequestType? type,
    String? title,
    String? description,
    SalesRequestStatus? status,
    DateTime? submissionDate,
    List<SalesTimelineEvent>? timeline,
    Map<String, dynamic>? details,
  }) {
    return SalesRequestItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      submissionDate: submissionDate ?? this.submissionDate,
      timeline: timeline ?? this.timeline,
      details: details ?? this.details,
    );
  }
}

enum SalesNotificationType { alert, schedule, info }

class SalesNotification {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final SalesNotificationType type;
  final bool isRead;

  const SalesNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  SalesNotification copyWith({bool? isRead}) {
    return SalesNotification(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}
