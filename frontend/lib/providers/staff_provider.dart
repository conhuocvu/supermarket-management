import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/staff_member.dart';
import '../services/api_service.dart';
import '../core/providers/api_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StaffListState {
  final List<StaffMember> staff;
  final bool isLoading;
  final String? error;
  final int totalStaff;
  final int onShiftCount;
  final String searchQuery;
  final String statusFilter; // ALL | ON_DUTY | OFF_DUTY | ON_LEAVE
  final int currentPage;
  final int totalPages;

  const StaffListState({
    this.staff = const [],
    this.isLoading = false,
    this.error,
    this.totalStaff = 0,
    this.onShiftCount = 0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.currentPage = 0,
    this.totalPages = 1,
  });

  StaffListState copyWith({
    List<StaffMember>? staff,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? totalStaff,
    int? onShiftCount,
    String? searchQuery,
    String? statusFilter,
    int? currentPage,
    int? totalPages,
  }) {
    return StaffListState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totalStaff: totalStaff ?? this.totalStaff,
      onShiftCount: onShiftCount ?? this.onShiftCount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
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
        page: state.currentPage,
        size: 6,
      );

      final rawList = result['staff'] as List;
      final items = rawList
          .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
          .toList();
      final totalStaff = result['totalStaff'] as int;
      final onShiftCount = result['onShiftCount'] as int;
      final totalPages = result['totalPages'] as int? ?? 1;

      state = state.copyWith(
        staff: items,
        isLoading: false,
        totalStaff: totalStaff,
        onShiftCount: onShiftCount,
        totalPages: totalPages,
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
    state = state.copyWith(searchQuery: query, currentPage: 0);
    loadStaff(isRefresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, searchQuery: '', currentPage: 0);
    loadStaff(isRefresh: true);
  }

  void setPage(int page) {
    if (page >= 0 && page < state.totalPages && page != state.currentPage) {
      state = state.copyWith(currentPage: page);
      loadStaff(isRefresh: true);
    }
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
