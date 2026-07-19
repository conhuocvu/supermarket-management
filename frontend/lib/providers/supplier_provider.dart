import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';
import 'category_provider.dart'; // provides apiServiceProvider

class SupplierListState {
  final List<Supplier> suppliers;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int totalSuppliers;
  final int activeCount;
  final int inactiveCount;
  final String searchQuery;
  final String statusFilter; // ALL | ACTIVE | INACTIVE
  final int currentPage;
  final int pageSize;
  final int totalPages;

  const SupplierListState({
    this.suppliers = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.totalSuppliers = 0,
    this.activeCount = 0,
    this.inactiveCount = 0,
    this.searchQuery = '',
    this.statusFilter = 'ALL',
    this.currentPage = 0,
    this.pageSize = 6,
    this.totalPages = 1,
  });

  SupplierListState copyWith({
    List<Supplier>? suppliers,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? totalSuppliers,
    int? activeCount,
    int? inactiveCount,
    String? searchQuery,
    String? statusFilter,
    int? currentPage,
    int? pageSize,
    int? totalPages,
  }) {
    return SupplierListState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      totalSuppliers: totalSuppliers ?? this.totalSuppliers,
      activeCount: activeCount ?? this.activeCount,
      inactiveCount: inactiveCount ?? this.inactiveCount,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class SupplierListNotifier extends StateNotifier<SupplierListState> {
  final ApiService _apiService;

  SupplierListNotifier(this._apiService) : super(const SupplierListState()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Fetch main list, active count, and inactive count in parallel to avoid network chaining latency
      final results = await Future.wait([
        _apiService.fetchSupplierList(
          keyword: state.searchQuery.isEmpty ? null : state.searchQuery,
          status: state.statusFilter,
          page: state.currentPage,
          size: state.pageSize,
        ),
        _apiService.fetchSupplierList(
          status: 'ACTIVE',
          page: 0,
          size: 1,
        ),
        _apiService.fetchSupplierList(
          status: 'INACTIVE',
          page: 0,
          size: 1,
        ),
      ]);

      final listResult = results[0];
      final activeResult = results[1];
      final inactiveResult = results[2];

      final rawItems = listResult['items'] as List? ?? [];
      final suppliersList = rawItems
          .map((item) => Supplier.fromJson(item as Map<String, dynamic>))
          .toList();

      final totalPages = (listResult['totalPages'] as num?)?.toInt() ?? 1;
      final currentPage = (listResult['page'] as num?)?.toInt() ?? 0;
      final activeCount = (activeResult['totalItems'] as num?)?.toInt() ?? 0;
      final inactiveCount = (inactiveResult['totalItems'] as num?)?.toInt() ?? 0;

      state = state.copyWith(
        suppliers: suppliersList,
        isLoading: false,
        totalSuppliers: activeCount + inactiveCount,
        activeCount: activeCount,
        inactiveCount: inactiveCount,
        currentPage: currentPage,
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
    loadSuppliers(isRefresh: true);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status, currentPage: 0);
    loadSuppliers(isRefresh: true);
  }

  void setPage(int page) {
    if (page < 0 || page >= state.totalPages) return;
    state = state.copyWith(currentPage: page);
    loadSuppliers(isRefresh: true);
  }

  /// Creates a supplier and returns the new supplierNumber.
  /// Throws on failure.
  Future<int> createSupplier(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final newId = await _apiService.createSupplier(data);
      state = state.copyWith(isSubmitting: false);
      return newId;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<bool> updateSupplier(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _apiService.updateSupplier(id, data);
      await loadSuppliers(isRefresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<bool> updateSupplierStatus(int id, String status) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _apiService.updateSupplierStatus(id, status);
      await loadSuppliers(isRefresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<Supplier> fetchSupplierById(int id) async {
    final data = await _apiService.fetchSupplierDetail(id);
    return Supplier.fromJson(data);
  }
}

final supplierListProvider =
    StateNotifierProvider<SupplierListNotifier, SupplierListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SupplierListNotifier(apiService);
});
