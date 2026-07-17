import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_member.dart';
import '../services/api_service.dart';
import 'category_provider.dart'; // provides apiServiceProvider

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StaffListState {
  final List<StaffMember> staff;
  final List<StaffMember> filteredStaff;
  final bool isLoading;
  final String? error;
  final int totalStaff;
  final int onShiftCount;
  final String searchQuery;
  final String statusFilter; // ALL | ON_DUTY | OFF_DUTY | ON_LEAVE

  const StaffListState({
    this.staff = const [],
    this.filteredStaff = const [],
    this.isLoading = false,
    this.error,
    this.totalStaff = 0,
    this.onShiftCount = 0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
  });

  StaffListState copyWith({
    List<StaffMember>? staff,
    List<StaffMember>? filteredStaff,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? totalStaff,
    int? onShiftCount,
    String? searchQuery,
    String? statusFilter,
  }) {
    return StaffListState(
      staff: staff ?? this.staff,
      filteredStaff: filteredStaff ?? this.filteredStaff,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totalStaff: totalStaff ?? this.totalStaff,
      onShiftCount: onShiftCount ?? this.onShiftCount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StaffListNotifier extends StateNotifier<StaffListState> {
  final ApiService _apiService;

  StaffListNotifier(this._apiService) : super(const StaffListState()) {
    loadStaff();
  }

  Future<void> loadStaff({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _apiService.fetchStaffList(
        keyword: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
      );

      final rawList = result['staff'] as List;
      final items = rawList
          .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
          .toList();
      final totalStaff = result['totalStaff'] as int;
      final onShiftCount = result['onShiftCount'] as int;

      state = state.copyWith(
        staff: items,
        filteredStaff: items,
        isLoading: false,
        totalStaff: totalStaff,
        onShiftCount: onShiftCount,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadStaff(isRefresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, searchQuery: '');
    loadStaff(isRefresh: true);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final staffListProvider =
    StateNotifierProvider<StaffListNotifier, StaffListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return StaffListNotifier(apiService);
});
