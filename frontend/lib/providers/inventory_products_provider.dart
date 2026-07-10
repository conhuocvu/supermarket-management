import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_item.dart';
import '../models/inventory_product.dart';
import '../services/api_service.dart';
import 'dashboard_provider.dart';

class InventoryProductsState {
  final AsyncValue<List<InventoryProduct>> products;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final String searchKeyword;
  final int? selectedCategoryNumber;
  final Set<int> selectedProductNumbers;
  final bool isSubmittingAction;
  final String? warningFilter;

  InventoryProductsState({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.searchKeyword,
    this.selectedCategoryNumber,
    required this.selectedProductNumbers,
    required this.isSubmittingAction,
    this.warningFilter = 'NONE',
  });

  InventoryProductsState copyWith({
    AsyncValue<List<InventoryProduct>>? products,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    String? searchKeyword,
    int? selectedCategoryNumber,
    Set<int>? selectedProductNumbers,
    bool? isSubmittingAction,
    String? warningFilter,
    bool clearCategory = false,
  }) {
    return InventoryProductsState(
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedCategoryNumber: clearCategory
          ? null
          : (selectedCategoryNumber ?? this.selectedCategoryNumber),
      selectedProductNumbers:
          selectedProductNumbers ?? this.selectedProductNumbers,
      isSubmittingAction: isSubmittingAction ?? this.isSubmittingAction,
      warningFilter: warningFilter ?? this.warningFilter,
    );
  }
}

class InventoryProductsNotifier extends StateNotifier<InventoryProductsState> {
  final ApiService _apiService;

  InventoryProductsNotifier(this._apiService)
    : super(
        InventoryProductsState(
          products: const AsyncValue.loading(),
          currentPage: 0,
          totalPages: 0,
          totalItems: 0,
          searchKeyword: '',
          selectedProductNumbers: {},
          isSubmittingAction: false,
          warningFilter: 'NONE',
        ),
      ) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(products: const AsyncValue.loading());
    try {
      final activeWarning = state.warningFilter ?? 'NONE';
      if (activeWarning != 'NONE') {
        final list = await _apiService.fetchWarningProducts(activeWarning);
        state = state.copyWith(
          products: AsyncValue.data(list),
          currentPage: 0,
          totalPages: 1,
          totalItems: list.length,
        );
      } else {
        final data = await _apiService.fetchInventoryProducts(
          keyword: state.searchKeyword,
          categoryNumber: state.selectedCategoryNumber,
          page: state.currentPage,
        );
        state = state.copyWith(
          products: AsyncValue.data(data['items'] as List<InventoryProduct>),
          currentPage: data['page'] as int,
          totalPages: data['totalPages'] as int,
          totalItems: data['totalItems'] as int,
        );
      }
    } catch (e, stack) {
      state = state.copyWith(products: AsyncValue.error(e, stack));
    }
  }

  void setSearchKeyword(String keyword) {
    if (state.searchKeyword != keyword) {
      state = state.copyWith(searchKeyword: keyword, currentPage: 0);
      loadProducts();
    }
  }

  void setCategoryNumber(int? categoryNumber) {
    if (state.selectedCategoryNumber != categoryNumber) {
      if (categoryNumber == null) {
        state = state.copyWith(clearCategory: true, currentPage: 0);
      } else {
        state = state.copyWith(
          selectedCategoryNumber: categoryNumber,
          currentPage: 0,
        );
      }
      loadProducts();
    }
  }

  void setWarningFilter(String warningFilter) {
    if ((state.warningFilter ?? 'NONE') != warningFilter) {
      state = state.copyWith(warningFilter: warningFilter, currentPage: 0);
      loadProducts();
    }
  }

  void toggleProductSelection(int productNumber) {
    final updated = Set<int>.from(state.selectedProductNumbers);
    if (updated.contains(productNumber)) {
      updated.remove(productNumber);
    } else {
      updated.add(productNumber);
    }
    state = state.copyWith(selectedProductNumbers: updated);
  }

  void clearSelection() {
    state = state.copyWith(selectedProductNumbers: {});
  }

  void selectAll(List<InventoryProduct> productsOnPage) {
    final updated = Set<int>.from(state.selectedProductNumbers);
    final activeOnPage = productsOnPage
        .where((p) => p.status == 'ACTIVE')
        .map((p) => p.productNumber)
        .toSet();
    if (activeOnPage.isEmpty) return;

    if (updated.containsAll(activeOnPage)) {
      updated.removeAll(activeOnPage);
    } else {
      updated.addAll(activeOnPage);
    }
    state = state.copyWith(selectedProductNumbers: updated);
  }

  void setPage(int page) {
    if (page >= 0 && page < state.totalPages && page != state.currentPage) {
      state = state.copyWith(currentPage: page);
      loadProducts();
    }
  }

  Future<void> toggleProductStatus(
    int productNumber,
    String currentStatus,
  ) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.updateProductStatus(productNumber, newStatus);
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }

  Future<void> submitPurchaseRequest() async {
    if (state.selectedProductNumbers.isEmpty) return;
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.createPurchaseRequest(
        state.selectedProductNumbers.toList(),
      );
      state = state.copyWith(selectedProductNumbers: {});
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }

  Future<void> submitPurchaseRequestForSingleProduct(int productNumber) async {
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.createPurchaseRequest([productNumber]);
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.createProduct(data);
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.updateProduct(id, data);
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }

  Future<void> deleteProduct(int productNumber) async {
    state = state.copyWith(isSubmittingAction: true);
    try {
      await _apiService.deleteProduct(productNumber);
      await loadProducts();
    } finally {
      state = state.copyWith(isSubmittingAction: false);
    }
  }
}

final inventoryProductsProvider =
    StateNotifierProvider<InventoryProductsNotifier, InventoryProductsState>((
      ref,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      return InventoryProductsNotifier(apiService);
    });

final categoriesListProvider = FutureProvider<List<CategoryItem>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchCategories();
});

final unitsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchUnits();
});

final suppliersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchSuppliers();
});
