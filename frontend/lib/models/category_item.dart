class CategoryItem {
  final int categoryNumber;
  final String categoryName;
  final String status;

  CategoryItem({
    required this.categoryNumber,
    required this.categoryName,
    required this.status,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      categoryNumber: (json['categoryNumber'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] ?? '',
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryNumber': categoryNumber,
      'categoryName': categoryName,
      'status': status,
    };
  }
}
