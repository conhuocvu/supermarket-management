import 'dashboard_data.dart';

class ManagerWeeklyRevenue {
  final String day;
  final double amount;

  ManagerWeeklyRevenue({required this.day, required this.amount});

  factory ManagerWeeklyRevenue.fromJson(Map<String, dynamic> json) {
    return ManagerWeeklyRevenue(
      day: json['day'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ManagerInventoryDistribution {
  final String categoryName;
  final double percentage;

  ManagerInventoryDistribution({required this.categoryName, required this.percentage});

  factory ManagerInventoryDistribution.fromJson(Map<String, dynamic> json) {
    return ManagerInventoryDistribution(
      categoryName: json['categoryName'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ManagerDashboardData {
  final int totalProducts;
  final int totalStaff;
  final int totalCustomers;
  final int totalSuppliers;
  final double totalRevenue;
  final double revenueToday;
  final int activeOrdersCount;
  final double stockLevel;
  final int lowStockCount;
  final List<ManagerWeeklyRevenue> weeklyRevenue;
  final List<ManagerInventoryDistribution> inventoryDistribution;
  final List<RecentActivity> recentActivities;
  final DateTime updatedAt;

  ManagerDashboardData({
    required this.totalProducts,
    required this.totalStaff,
    required this.totalCustomers,
    required this.totalSuppliers,
    required this.totalRevenue,
    required this.revenueToday,
    required this.activeOrdersCount,
    required this.stockLevel,
    required this.lowStockCount,
    required this.weeklyRevenue,
    required this.inventoryDistribution,
    required this.recentActivities,
    required this.updatedAt,
  });

  factory ManagerDashboardData.fromJson(Map<String, dynamic> json) {
    var weeklyRevList = (json['weeklyRevenue'] as List? ?? [])
        .map((i) => ManagerWeeklyRevenue.fromJson(i))
        .toList();
    var invDistList = (json['inventoryDistribution'] as List? ?? [])
        .map((i) => ManagerInventoryDistribution.fromJson(i))
        .toList();
    var recentActList = (json['recentActivities'] as List? ?? [])
        .map((i) => RecentActivity.fromJson(i))
        .toList();

    return ManagerDashboardData(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalStaff: (json['totalStaff'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalSuppliers: (json['totalSuppliers'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
      activeOrdersCount: (json['activeOrdersCount'] as num?)?.toInt() ?? 0,
      stockLevel: (json['stockLevel'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      weeklyRevenue: weeklyRevList,
      inventoryDistribution: invDistList,
      recentActivities: recentActList,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
