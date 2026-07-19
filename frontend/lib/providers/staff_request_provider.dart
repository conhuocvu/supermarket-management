import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_request.dart';
import '../services/staff_request_api_service.dart';

final staffRequestApiServiceProvider = Provider<StaffRequestApiService>((ref) {
  return StaffRequestApiService();
});

final staffRequestProvider =
    StateNotifierProvider<StaffRequestNotifier, StaffRequestState>((ref) {
      final apiService = ref.watch(staffRequestApiServiceProvider);
      return StaffRequestNotifier(apiService);
    });

class StaffRequestState {
  final List<StaffRequest> items;
  final bool isLoading;
  final String? errorMessage;

  final int page;
  final int size;
  final int totalItems;
  final int totalPages;

  final String requestType;
  final String status;
  final String keyword;

  const StaffRequestState({
    this.items = const [],
    this.isLoading = true,
    this.errorMessage,
    this.page = 0,
    this.size = 10,
    this.totalItems = 0,
    this.totalPages = 0,
    this.requestType = 'ALL',
    this.status = 'ALL',
    this.keyword = '',
  });

  bool get hasPreviousPage => page > 0;

  bool get hasNextPage => page + 1 < totalPages;

  StaffRequestState copyWith({
    List<StaffRequest>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? size,
    int? totalItems,
    int? totalPages,
    String? requestType,
    String? status,
    String? keyword,
  }) {
    return StaffRequestState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      page: page ?? this.page,
      size: size ?? this.size,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
    );
  }
}

class StaffRequestNotifier extends StateNotifier<StaffRequestState> {
  final StaffRequestApiService _apiService;

  Timer? _searchDebounce;
  int _requestSequence = 0;

  StaffRequestNotifier(this._apiService) : super(const StaffRequestState()) {
    loadRequests();
  }

  Future<void> loadRequests({bool resetPage = false}) async {
    final targetPage = resetPage ? 0 : state.page;
    final currentRequest = ++_requestSequence;

    state = state.copyWith(isLoading: true, page: targetPage, clearError: true);

    try {
      final result = await _apiService.fetchStaffRequests(
        page: targetPage,
        size: state.size,
        requestType: state.requestType,
        status: state.status,
        keyword: state.keyword,
      );

      // Bỏ qua kết quả cũ nếu người dùng vừa đổi bộ lọc.
      if (currentRequest != _requestSequence) {
        return;
      }

      final rawItems = result['items'];

      final items = rawItems is List
          ? rawItems.whereType<StaffRequest>().toList()
          : <StaffRequest>[];

      state = state.copyWith(
        items: items,
        isLoading: false,
        page: _parseInt(result['page'], targetPage),
        size: _parseInt(result['size'], state.size),
        totalItems: _parseInt(result['totalItems'], 0),
        totalPages: _parseInt(result['totalPages'], 0),
        clearError: true,
      );
    } catch (error) {
      if (currentRequest != _requestSequence) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> refresh() async {
    await loadRequests();
  }

  Future<void> updateRequestType(String requestType) async {
    if (state.requestType == requestType) {
      return;
    }

    state = state.copyWith(requestType: requestType, page: 0);

    await loadRequests(resetPage: true);
  }

  Future<void> updateStatus(String status) async {
    if (state.status == status) {
      return;
    }

    state = state.copyWith(status: status, page: 0);

    await loadRequests(resetPage: true);
  }

  void updateKeyword(String keyword) {
    state = state.copyWith(keyword: keyword, page: 0);

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      loadRequests(resetPage: true);
    });
  }

  Future<void> nextPage() async {
    if (!state.hasNextPage || state.isLoading) {
      return;
    }

    state = state.copyWith(page: state.page + 1);
    await loadRequests();
  }

  Future<void> previousPage() async {
    if (!state.hasPreviousPage || state.isLoading) {
      return;
    }

    state = state.copyWith(page: state.page - 1);
    await loadRequests();
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
