class Certification {
  final int id;
  final String name;
  final DateTime obtainedDate;
  final DateTime? expiryDate;

  Certification({
    required this.id,
    required this.name,
    required this.obtainedDate,
    this.expiryDate,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] as int,
      name: json['name'] as String,
      obtainedDate: DateTime.parse(json['obtainedDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'obtainedDate': obtainedDate.toIso8601String().substring(0, 10),
      'expiryDate': expiryDate?.toIso8601String().substring(0, 10),
    };
  }
}
