class StaffMember {
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String status;
  final int? roleNumber;
  final String roleName;
  final String workStatus; // ON_DUTY | OFF_DUTY | ON_LEAVE
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;

  const StaffMember({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.status,
    this.roleNumber,
    required this.roleName,
    required this.workStatus,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      roleNumber: json['roleNumber'] as int?,
      roleName: json['roleName'] as String? ?? 'Unknown',
      workStatus: json['workStatus'] as String? ?? 'OFF_DUTY',
      shiftName: json['shiftName'] as String?,
      shiftStartTime: json['shiftStartTime'] as String?,
      shiftEndTime: json['shiftEndTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'status': status,
      'roleNumber': roleNumber,
      'roleName': roleName,
      'workStatus': workStatus,
      'shiftName': shiftName,
      'shiftStartTime': shiftStartTime,
      'shiftEndTime': shiftEndTime,
    };
  }

  /// Formatted shift time range, e.g. "08:00 - 16:00"
  String get shiftTimeRange {
    if (shiftStartTime == null || shiftEndTime == null) return '';
    final start = shiftStartTime!.length >= 5 ? shiftStartTime!.substring(0, 5) : shiftStartTime!;
    final end = shiftEndTime!.length >= 5 ? shiftEndTime!.substring(0, 5) : shiftEndTime!;
    return '$start - $end';
  }
}
