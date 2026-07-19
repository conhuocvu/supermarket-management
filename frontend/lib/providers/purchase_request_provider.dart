import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_request.dart';
import '../services/api_service.dart';
import 'dashboard_provider.dart';

final purchaseRequestsProvider = FutureProvider.autoDispose<List<PurchaseRequestList>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchPurchaseRequests();
});

class PurchaseRequestOperationsState {
  final bool isLoading;
  final String? error;
  final dynamic data;

  PurchaseRequestOperationsState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  PurchaseRequestOperationsState copyWith({
    bool? isLoading,
    String? error,
    dynamic data,
  }) {
    return PurchaseRequestOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class PurchaseRequestOperationsNotifier extends StateNotifier<PurchaseRequestOperationsState> {
  final ApiService _apiService;
  final Ref _ref;

  PurchaseRequestOperationsNotifier(this._apiService, this._ref)
      : super(PurchaseRequestOperationsState());

  Future<void> createPurchaseRequestFromLowStock(List<int> productNumbers) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.createPurchaseRequest(productNumbers);
      state = state.copyWith(isLoading: false);
      _ref.invalidate(purchaseRequestsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<PurchaseRequestDetail> saveDraft(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.saveDraftPurchaseRequest(payload);
      state = state.copyWith(isLoading: false, data: res);
      _ref.invalidate(purchaseRequestsProvider);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> submitForApproval(int prNumber) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.submitPurchaseRequestForApproval(prNumber);
      state = state.copyWith(isLoading: false);
      _ref.invalidate(purchaseRequestsProvider);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final purchaseRequestOperationsProvider =
    StateNotifierProvider<PurchaseRequestOperationsNotifier, PurchaseRequestOperationsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PurchaseRequestOperationsNotifier(apiService, ref);
});
