class Product {
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

  Product({
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

  Product copyWith({
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
    return Product(
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
