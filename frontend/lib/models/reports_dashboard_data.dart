class ReportsDashboardData {
  final StatisticsSection statistics;
  final RevenueSection revenue;
  final InventorySection inventory;
  final WasteSection waste;

  ReportsDashboardData({
    required this.statistics,
    required this.revenue,
    required this.inventory,
    required this.waste,
  });

  factory ReportsDashboardData.fromJson(Map<String, dynamic> json) {
    return ReportsDashboardData(
      statistics: StatisticsSection.fromJson(json['statistics'] ?? {}),
      revenue: RevenueSection.fromJson(json['revenue'] ?? {}),
      inventory: InventorySection.fromJson(json['inventory'] ?? {}),
      waste: WasteSection.fromJson(json['waste'] ?? {}),
    );
  }
}

class StatisticsSection {
  final double grossSales;
  final String grossSalesTrend;
  final double avgBasket;
  final String avgBasketTrend;
  final double stockTurn;
  final String stockTurnTrend;
  final int footTraffic;
  final String footTrafficTrend;
  final List<SalesVelocityPoint> salesVelocity;
  final List<CategoryPercentage> topCategories;
  final List<Anomaly> recentAnomalies;

  StatisticsSection({
    required this.grossSales,
    required this.grossSalesTrend,
    required this.avgBasket,
    required this.avgBasketTrend,
    required this.stockTurn,
    required this.stockTurnTrend,
    required this.footTraffic,
    required this.footTrafficTrend,
    required this.salesVelocity,
    required this.topCategories,
    required this.recentAnomalies,
  });

  factory StatisticsSection.fromJson(Map<String, dynamic> json) {
    return StatisticsSection(
      grossSales: (json['grossSales'] as num?)?.toDouble() ?? 0.0,
      grossSalesTrend: json['grossSalesTrend'] as String? ?? '',
      avgBasket: (json['avgBasket'] as num?)?.toDouble() ?? 0.0,
      avgBasketTrend: json['avgBasketTrend'] as String? ?? '',
      stockTurn: (json['stockTurn'] as num?)?.toDouble() ?? 0.0,
      stockTurnTrend: json['stockTurnTrend'] as String? ?? '',
      footTraffic: json['footTraffic'] as int? ?? 0,
      footTrafficTrend: json['footTrafficTrend'] as String? ?? '',
      salesVelocity: (json['salesVelocity'] as List?)
              ?.map((e) => SalesVelocityPoint.fromJson(e))
              .toList() ??
          [],
      topCategories: (json['topCategories'] as List?)
              ?.map((e) => CategoryPercentage.fromJson(e))
              .toList() ??
          [],
      recentAnomalies: (json['recentAnomalies'] as List?)
              ?.map((e) => Anomaly.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RevenueSection {
  final double netSales;
  final String netSalesTrend;
  final double netProfit;
  final String netProfitTrend;
  final double grossMargin;
  final String grossMarginTrend;
  final List<SalesVelocityPoint> revenueTrend;

  RevenueSection({
    required this.netSales,
    required this.netSalesTrend,
    required this.netProfit,
    required this.netProfitTrend,
    required this.grossMargin,
    required this.grossMarginTrend,
    required this.revenueTrend,
  });

  factory RevenueSection.fromJson(Map<String, dynamic> json) {
    return RevenueSection(
      netSales: (json['netSales'] as num?)?.toDouble() ?? 0.0,
      netSalesTrend: json['netSalesTrend'] as String? ?? '',
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      netProfitTrend: json['netProfitTrend'] as String? ?? '',
      grossMargin: (json['grossMargin'] as num?)?.toDouble() ?? 0.0,
      grossMarginTrend: json['grossMarginTrend'] as String? ?? '',
      revenueTrend: (json['revenueTrend'] as List?)
              ?.map((e) => SalesVelocityPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class InventorySection {
  final double totalStockValue;
  final String stockValueTrend;
  final int lowStockAlerts;
  final double stockTurnoverRate;
  final List<CategoryPercentage> inventoryDistribution;

  InventorySection({
    required this.totalStockValue,
    required this.stockValueTrend,
    required this.lowStockAlerts,
    required this.stockTurnoverRate,
    required this.inventoryDistribution,
  });

  factory InventorySection.fromJson(Map<String, dynamic> json) {
    return InventorySection(
      totalStockValue: (json['totalStockValue'] as num?)?.toDouble() ?? 0.0,
      stockValueTrend: json['stockValueTrend'] as String? ?? '',
      lowStockAlerts: json['lowStockAlerts'] as int? ?? 0,
      stockTurnoverRate: (json['stockTurnoverRate'] as num?)?.toDouble() ?? 0.0,
      inventoryDistribution: (json['inventoryDistribution'] as List?)
              ?.map((e) => CategoryPercentage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WasteSection {
  final double totalWasteValue;
  final String wasteValueTrend;
  final int wasteItemsCount;
  final List<Anomaly> recentWasteEvents;

  WasteSection({
    required this.totalWasteValue,
    required this.wasteValueTrend,
    required this.wasteItemsCount,
    required this.recentWasteEvents,
  });

  factory WasteSection.fromJson(Map<String, dynamic> json) {
    return WasteSection(
      totalWasteValue: (json['totalWasteValue'] as num?)?.toDouble() ?? 0.0,
      wasteValueTrend: json['wasteValueTrend'] as String? ?? '',
      wasteItemsCount: json['wasteItemsCount'] as int? ?? 0,
      recentWasteEvents: (json['recentWasteEvents'] as List?)
              ?.map((e) => Anomaly.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SalesVelocityPoint {
  final String label;
  final double amount;

  SalesVelocityPoint({
    required this.label,
    required this.amount,
  });

  factory SalesVelocityPoint.fromJson(Map<String, dynamic> json) {
    return SalesVelocityPoint(
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryPercentage {
  final String categoryName;
  final double percentage;

  CategoryPercentage({
    required this.categoryName,
    required this.percentage,
  });

  factory CategoryPercentage.fromJson(Map<String, dynamic> json) {
    return CategoryPercentage(
      categoryName: json['categoryName'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Anomaly {
  final String timestamp;
  final String entity;
  final String eventType;
  final String value;
  final String action;

  Anomaly({
    required this.timestamp,
    required this.entity,
    required this.eventType,
    required this.value,
    required this.action,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      timestamp: json['timestamp'] as String? ?? '',
      entity: json['entity'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      value: json['value'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }
}
