class Shift {
  final int id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String shiftType;
  final String? register;
  final bool completed;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftType,
    this.register,
    required this.completed,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      startTime: (json['startTime'] as String).substring(0, 5),
      endTime: (json['endTime'] as String).substring(0, 5),
      shiftType: json['shiftType'] as String,
      register: json['register'] as String?,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'startTime': startTime,
      'endTime': endTime,
      'shiftType': shiftType,
      'register': register,
      'completed': completed,
    };
  }
}
