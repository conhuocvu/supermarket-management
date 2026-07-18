class Promotion {
  final int? id;
  final int promotionNumber;
  final String promotionName;
  final double discountValue;
  final String status; // ACTIVE | SCHEDULED | EXPIRED
  final String? startDate;
  final String? endDate;
  final String? description;
  final String? imageUrl;
  final String? visibility;
  final String promoCode;
  final String category;
  final bool isFeatured;

  const Promotion({
    this.id,
    required this.promotionNumber,
    required this.promotionName,
    required this.discountValue,
    required this.status,
    this.startDate,
    this.endDate,
    this.description,
    this.imageUrl,
    this.visibility,
    required this.promoCode,
    required this.category,
    required this.isFeatured,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as int?,
      promotionNumber: (json['promotionNumber'] as num?)?.toInt() ?? 0,
      promotionName: json['promotionName'] as String? ?? '',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'ACTIVE',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      visibility: json['visibility'] as String?,
      promoCode: json['promoCode'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotionNumber': promotionNumber,
      'promotionName': promotionName,
      'discountValue': discountValue,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'imageUrl': imageUrl,
      'visibility': visibility,
      'promoCode': promoCode,
      'category': category,
      'isFeatured': isFeatured,
    };
  }

  /// Calculates human readable remaining days or ended string
  String get timeStatusLabel {
    if (endDate == null) return '';
    try {
      final now = DateTime.now();
      final end = DateTime.parse(endDate!);
      final difference = end.difference(now).inDays;
      if (difference < 0) {
        // Look up month name
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return 'Ended ${months[end.month - 1]} ${end.day}';
      } else if (difference == 0) {
        return 'Ends today';
      } else {
        return 'Ends in $difference days';
      }
    } catch (_) {
      return '';
    }
  }

  /// Calculates human readable starts in or starts date label
  String get startStatusLabel {
    if (startDate == null) return '';
    try {
      final now = DateTime.now();
      final start = DateTime.parse(startDate!);
      final difference = start.difference(now).inDays;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      if (difference > 0) {
        return 'Starts ${months[start.month - 1]} ${start.day}';
      } else {
        return 'Started';
      }
    } catch (_) {
      return '';
    }
  }
}
