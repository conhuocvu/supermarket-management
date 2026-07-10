class RecentActivity {
  final String action;
  final String item;
  final String quantity;
  final DateTime time;

  RecentActivity({
    required this.action,
    required this.item,
    required this.quantity,
    required this.time,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      action: json['action'] ?? '',
      item: json['item'] ?? '',
      quantity: json['quantity'] ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'item': item,
      'quantity': quantity,
      'time': time.toIso8601String(),
    };
  }
}

class DashboardData {
  final int totalProducts;
  final int lowStockCount;
  final int nearExpiryCount;
  final int pendingRequestsCount;
  final double capacityUsed;
  final List<RecentActivity> recentActivities;
  final DateTime updatedAt;

  DashboardData({
    required this.totalProducts,
    required this.lowStockCount,
    required this.nearExpiryCount,
    required this.pendingRequestsCount,
    required this.capacityUsed,
    required this.recentActivities,
    required this.updatedAt,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var list = json['recentActivities'] as List? ?? [];
    List<RecentActivity> activitiesList = list
        .map((i) => RecentActivity.fromJson(i))
        .toList();

    return DashboardData(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      nearExpiryCount: (json['nearExpiryCount'] as num?)?.toInt() ?? 0,
      pendingRequestsCount:
          (json['pendingRequestsCount'] as num?)?.toInt() ?? 0,
      capacityUsed: (json['capacityUsed'] as num?)?.toDouble() ?? 0.0,
      recentActivities: activitiesList,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
      'nearExpiryCount': nearExpiryCount,
      'pendingRequestsCount': pendingRequestsCount,
      'capacityUsed': capacityUsed,
      'recentActivities': recentActivities.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
