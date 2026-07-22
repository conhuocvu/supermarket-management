import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'category_provider.dart'; // provides apiServiceProvider

class PromotionListState {
  final List<Promotion> promotions;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int activeCount;
  final int scheduledCount;
  final int expiredCount;
  final double avgDiscount;
  final String searchQuery;
  final String statusFilter; // ALL | ACTIVE | SCHEDULED | EXPIRED
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalElements;

  const PromotionListState({
    this.promotions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.activeCount = 0,
    this.scheduledCount = 0,
    this.expiredCount = 0,
    this.avgDiscount = 0.0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.page = 0,
    this.pageSize = 6,
    this.totalPages = 0,
    this.totalElements = 0,
  });

  PromotionListState copyWith({
    List<Promotion>? promotions,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? activeCount,
    int? scheduledCount,
    int? expiredCount,
    double? avgDiscount,
    String? searchQuery,
    String? statusFilter,
    int? page,
    int? pageSize,
    int? totalPages,
    int? totalElements,
  }) {
    return PromotionListState(
      promotions: promotions ?? this.promotions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      activeCount: activeCount ?? this.activeCount,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      expiredCount: expiredCount ?? this.expiredCount,
      avgDiscount: avgDiscount ?? this.avgDiscount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
    );
  }
}

class PromotionListNotifier extends StateNotifier<PromotionListState> {
  final ApiService _apiService;

  PromotionListNotifier(this._apiService) : super(const PromotionListState()) {
    loadPromotions();
  }

  Future<void> loadPromotions({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _apiService.fetchPromotions(
        keyword: state.searchQuery.isEmpty ? null : state.searchQuery,
        status: state.statusFilter,
        page: state.page,
        size: state.pageSize,
      );

      final rawList = result['promotions'] as List? ?? [];
      final items = rawList
          .map((item) => Promotion.fromJson(item as Map<String, dynamic>))
          .toList();

      final activeCount = (result['activeCount'] as num?)?.toInt() ?? 0;
      final scheduledCount = (result['scheduledCount'] as num?)?.toInt() ?? 0;
      final expiredCount = (result['expiredCount'] as num?)?.toInt() ?? 0;
      final avgDiscount = (result['avgDiscount'] as num?)?.toDouble() ?? 0.0;
      final currentPage = (result['currentPage'] as num?)?.toInt() ?? 0;
      final totalPages = (result['totalPages'] as num?)?.toInt() ?? 0;
      final totalElements = (result['totalElements'] as num?)?.toInt() ?? 0;

      state = state.copyWith(
        promotions: items,
        isLoading: false,
        activeCount: activeCount,
        scheduledCount: scheduledCount,
        expiredCount: expiredCount,
        avgDiscount: avgDiscount,
        page: currentPage,
        totalPages: totalPages,
        totalElements: totalElements,
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
    state = state.copyWith(searchQuery: query, page: 0);
    loadPromotions(isRefresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, page: 0);
    loadPromotions(isRefresh: true);
  }

  void goToPage(int page) {
    if (page < 0 || page >= state.totalPages) return;
    state = state.copyWith(page: page);
    loadPromotions(isRefresh: true);
  }

  /// Create a new promotion and refresh the list.
  Future<void> createPromotion(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _apiService.createPromotion(data);
      await loadPromotions(isRefresh: true);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// Update an existing promotion and refresh the list.
  Future<void> updatePromotion(int promotionNumber, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _apiService.updatePromotion(promotionNumber, data);
      await loadPromotions(isRefresh: true);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// Deactivate a promotion and refresh the list.
  Future<void> deactivatePromotion(int promotionNumber) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _apiService.deactivatePromotion(promotionNumber);
      await loadPromotions(isRefresh: true);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final promotionListProvider =
    StateNotifierProvider<PromotionListNotifier, PromotionListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PromotionListNotifier(apiService);
});
