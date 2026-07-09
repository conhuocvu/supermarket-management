class Promotion {
  final int id;
  final String name;
  final String code;
  final String description;
  final String priority;
  final String discountType;
  final double discountValue;
  final List<String> targetCategories;
  final List<String> targetProducts;
  final DateTime startDate;
  final DateTime endDate;
  final String imageUrl;
  final String visibility;
  final String status;
  final int productsCount;

  // Analytics mock data
  final String estRevenueIncrease;
  final int productsSold;
  final int usageRate;
  final List<int> dailyEngagement;

  Promotion({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.priority,
    required this.discountType,
    required this.discountValue,
    required this.targetCategories,
    required this.targetProducts,
    required this.startDate,
    required this.endDate,
    required this.imageUrl,
    required this.visibility,
    required this.status,
    required this.productsCount,
    required this.estRevenueIncrease,
    required this.productsSold,
    required this.usageRate,
    required this.dailyEngagement,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    var categoriesJson = json['targetCategories'] as List? ?? [];
    var productsJson = json['targetProducts'] as List? ?? [];
    var engagementJson = json['dailyEngagement'] as List? ?? [];

    return Promotion(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      targetCategories: categoriesJson.map((e) => e.toString()).toList(),
      targetProducts: productsJson.map((e) => e.toString()).toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      imageUrl: json['imageUrl'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'Storewide & Online',
      status: json['status'] as String? ?? 'ACTIVE',
      productsCount: json['productsCount'] as int? ?? 0,
      estRevenueIncrease: json['estRevenueIncrease'] as String? ?? '+10.0%',
      productsSold: json['productsSold'] as int? ?? 0,
      usageRate: json['usageRate'] as int? ?? 0,
      dailyEngagement: engagementJson.map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'priority': priority,
      'discountType': discountType,
      'discountValue': discountValue,
      'targetCategories': targetCategories,
      'targetProducts': targetProducts,
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate.toIso8601String().substring(0, 10),
      'imageUrl': imageUrl,
      'visibility': visibility,
      'status': status,
      'productsCount': productsCount,
      'estRevenueIncrease': estRevenueIncrease,
      'productsSold': productsSold,
      'usageRate': usageRate,
      'dailyEngagement': dailyEngagement,
    };
  }
}
