class CategoryItem {
  final int categoryNumber;
  final int? parentCategoryNumber;
  final String? parentCategoryName;
  final String categoryName;
  final String status;
  final String? description;
  final String? internalNotes;

  CategoryItem({
    required this.categoryNumber,
    this.parentCategoryNumber,
    this.parentCategoryName,
    required this.categoryName,
    required this.status,
    this.description,
    this.internalNotes,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      categoryNumber: (json['categoryNumber'] as num?)?.toInt() ?? 0,
      parentCategoryNumber: (json['parentCategoryNumber'] as num?)?.toInt(),
      parentCategoryName: json['parentCategoryName'],
      categoryName: json['categoryName'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      description: json['description'],
      internalNotes: json['internalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryNumber': categoryNumber,
      'parentCategoryNumber': parentCategoryNumber,
      'parentCategoryName': parentCategoryName,
      'categoryName': categoryName,
      'status': status,
      'description': description,
      'internalNotes': internalNotes,
    };
  }
}
