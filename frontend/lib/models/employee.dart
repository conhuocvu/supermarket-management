import 'certification.dart';
import 'shift.dart';

class Employee {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String location;
  final DateTime joinedDate;
  final String role;
  final String status;
  final double attendanceRate;
  final int completedShifts;
  final double performanceScore;
  final String? managersNote;
  final DateTime? returnsDate;
  final String imageUrl;
  final List<Shift> recentShifts;
  final List<Certification> certifications;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.joinedDate,
    required this.role,
    required this.status,
    required this.attendanceRate,
    required this.completedShifts,
    required this.performanceScore,
    this.managersNote,
    this.returnsDate,
    required this.imageUrl,
    required this.recentShifts,
    required this.certifications,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    var shiftsJson = json['recentShifts'] as List? ?? [];
    var certsJson = json['certifications'] as List? ?? [];

    return Employee(
      id: json['id'] as int,
      employeeCode: json['employeeCode'] as String? ?? 'EMP-${json['id']}',
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      location: json['location'] as String? ?? '',
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      role: json['role'] as String,
      status: json['status'] as String,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 100.0,
      completedShifts: json['completedShifts'] as int? ?? 0,
      performanceScore: (json['performanceScore'] as num?)?.toDouble() ?? 5.0,
      managersNote: json['managersNote'] as String?,
      returnsDate: json['returnsDate'] != null
          ? DateTime.parse(json['returnsDate'] as String)
          : null,
      imageUrl: json['imageUrl'] as String? ?? '',
      recentShifts: shiftsJson.map((e) => Shift.fromJson(e)).toList(),
      certifications: certsJson.map((e) => Certification.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'joinedDate': joinedDate.toIso8601String().substring(0, 10),
      'role': role,
      'status': status,
      'attendanceRate': attendanceRate,
      'completedShifts': completedShifts,
      'performanceScore': performanceScore,
      'managersNote': managersNote,
      'returnsDate': returnsDate?.toIso8601String().substring(0, 10),
      'imageUrl': imageUrl,
      'recentShifts': recentShifts.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
    };
  }
}
