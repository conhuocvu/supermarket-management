import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'dashboard_provider.dart' show apiServiceProvider;

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AsyncValue<AttendanceState>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AttendanceNotifier(apiService);
});

class AttendanceState {
  final int? attendanceNumber;
  final String? userId;
  final DateTime? workDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? status;
  final int? durationMinutes;

  AttendanceState({
    this.attendanceNumber,
    this.userId,
    this.workDate,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.durationMinutes,
  });

  bool get isCheckedIn => status == 'CHECKED_IN';
  bool get hasNoRecord => attendanceNumber == null;

  factory AttendanceState.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AttendanceState();
    }
    return AttendanceState(
      attendanceNumber: json['attendanceNumber'] as int?,
      userId: json['userId'] as String?,
      workDate: json['workDate'] != null ? DateTime.parse(json['workDate']) : null,
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      status: json['status'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AsyncValue<AttendanceState>> {
  final ApiService _apiService;

  AttendanceNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> loadTodayAttendance(String userId) async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.fetchTodayAttendance(userId);
      state = AsyncValue.data(AttendanceState.fromJson(data));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> checkIn(String userId) async {
    try {
      final data = await _apiService.checkIn(userId);
      state = AsyncValue.data(AttendanceState.fromJson(data));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> checkOut(String userId) async {
    try {
      final data = await _apiService.checkOut(userId);
      state = AsyncValue.data(AttendanceState.fromJson(data));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> refresh(String userId) async {
    try {
      final data = await _apiService.fetchTodayAttendance(userId);
      state = AsyncValue.data(AttendanceState.fromJson(data));
    } catch (e, stackTrace) {
      if (state.hasValue) {
        rethrow;
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}
