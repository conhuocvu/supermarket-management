import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'category_provider.dart'; // provides apiServiceProvider

class PromotionListState {
  final List<Promotion> promotions;
  final bool isLoading;
  final String? error;
  final int activeCount;
  final int scheduledCount;
  final int expiredCount;
  final double avgDiscount;
  final String searchQuery;
  final String statusFilter; // ALL | ACTIVE | SCHEDULED | EXPIRED

  const PromotionListState({
    this.promotions = const [],
    this.isLoading = false,
    this.error,
    this.activeCount = 0,
    this.scheduledCount = 0,
    this.expiredCount = 0,
    this.avgDiscount = 0.0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
  });

  PromotionListState copyWith({
    List<Promotion>? promotions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? activeCount,
    int? scheduledCount,
    int? expiredCount,
    double? avgDiscount,
    String? searchQuery,
    String? statusFilter,
  }) {
    return PromotionListState(
      promotions: promotions ?? this.promotions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeCount: activeCount ?? this.activeCount,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      expiredCount: expiredCount ?? this.expiredCount,
      avgDiscount: avgDiscount ?? this.avgDiscount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
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
      );

      final rawList = result['promotions'] as List? ?? [];
      final items = rawList
          .map((item) => Promotion.fromJson(item as Map<String, dynamic>))
          .toList();

      final activeCount = (result['activeCount'] as num?)?.toInt() ?? 0;
      final scheduledCount = (result['scheduledCount'] as num?)?.toInt() ?? 0;
      final expiredCount = (result['expiredCount'] as num?)?.toInt() ?? 0;
      final avgDiscount = (result['avgDiscount'] as num?)?.toDouble() ?? 0.0;

      state = state.copyWith(
        promotions: items,
        isLoading: false,
        activeCount: activeCount,
        scheduledCount: scheduledCount,
        expiredCount: expiredCount,
        avgDiscount: avgDiscount,
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
    loadPromotions(isRefresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
    loadPromotions(isRefresh: true);
  }
}

final promotionListProvider =
    StateNotifierProvider<PromotionListNotifier, PromotionListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PromotionListNotifier(apiService);
});
