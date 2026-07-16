import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manager_dashboard_data.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final managerDashboardDataProvider =
    StateNotifierProvider<ManagerDashboardDataNotifier, AsyncValue<ManagerDashboardData>>((
      ref,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      return ManagerDashboardDataNotifier(apiService);
    });

class ManagerDashboardDataNotifier extends StateNotifier<AsyncValue<ManagerDashboardData>> {
  final ApiService _apiService;

  ManagerDashboardDataNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.fetchManagerDashboardData();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshDashboard() async {
    try {
      final data = await _apiService.fetchManagerDashboardData();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      if (state.hasValue) {
        rethrow;
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}
