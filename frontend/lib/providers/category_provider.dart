import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_item.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class CategoryListState {
  final List<CategoryItem> categories;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final String searchQuery;

  CategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.totalPages = 1,
    this.totalItems = 0,
    this.searchQuery = '',
  });

  CategoryListState copyWith({
    List<CategoryItem>? categories,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    String? searchQuery,
  }) {
    return CategoryListState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error, // Can be set to null
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CategoryListNotifier extends StateNotifier<CategoryListState> {
  final ApiService _apiService;

  CategoryListNotifier(this._apiService) : super(CategoryListState()) {
    loadCategories();
  }

  Future<void> loadCategories({bool isRefresh = false, String? query}) async {
    if (state.isLoading) return;

    if (query != null) {
      state = state.copyWith(
          searchQuery: query, currentPage: 0, categories: [], isLoading: true);
    } else if (isRefresh) {
      state = state.copyWith(currentPage: 0, categories: [], isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _apiService.getCategories(
        keyword: state.searchQuery,
        page: state.currentPage,
        size: 10,
      );

      final data = response['data'] as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      
      final parsedCategories =
          items.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        categories: parsedCategories,
        currentPage: data['page'] ?? 0,
        totalPages: data['totalPages'] ?? 1,
        totalItems: data['totalItems'] ?? 0,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || state.currentPage >= state.totalPages - 1) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _apiService.getCategories(
        keyword: state.searchQuery,
        page: nextPage,
        size: 10,
      );

      final data = response['data'] as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      
      final newCategories =
          items.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        categories: newCategories,
        currentPage: nextPage,
        totalPages: data['totalPages'] ?? state.totalPages,
        totalItems: data['totalItems'] ?? state.totalItems,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> loadPreviousPage() async {
    if (state.isLoadingMore || state.currentPage <= 0) return;
    
    state = state.copyWith(isLoadingMore: true);
    try {
      final prevPage = state.currentPage - 1;
      final response = await _apiService.getCategories(
        keyword: state.searchQuery,
        page: prevPage,
        size: 10,
      );

      final data = response['data'] as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      
      final newCategories =
          items.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        categories: newCategories,
        currentPage: prevPage,
        totalPages: data['totalPages'] ?? state.totalPages,
        totalItems: data['totalItems'] ?? state.totalItems,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> goToPage(int pageIndex) async {
    if (state.isLoadingMore || pageIndex < 0 || pageIndex >= state.totalPages) return;
    
    state = state.copyWith(isLoadingMore: true);
    try {
      final response = await _apiService.getCategories(
        keyword: state.searchQuery,
        page: pageIndex,
        size: 10,
      );

      final data = response['data'] as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      
      final newCategories =
          items.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        categories: newCategories,
        currentPage: pageIndex,
        totalPages: data['totalPages'] ?? state.totalPages,
        totalItems: data['totalItems'] ?? state.totalItems,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void search(String query) {
    loadCategories(query: query);
  }

  Future<void> updateCategoryStatus(int categoryNumber, String newStatus) async {
    try {
      await _apiService.updateCategoryStatus(categoryNumber, newStatus);
      
      // Refresh to ensure all child categories are synced
      loadCategories(isRefresh: true);
    } catch (e) {
      // Refresh to ensure sync if failed
      loadCategories(isRefresh: true);
      rethrow;
    }
  }
}

final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, CategoryListState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CategoryListNotifier(apiService);
});
