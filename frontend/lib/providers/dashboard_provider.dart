import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

import 'employee_provider.dart';
export 'employee_provider.dart' show apiServiceProvider;

final dashboardDataProvider =
    StateNotifierProvider<DashboardDataNotifier, AsyncValue<DashboardData>>((
      ref,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      return DashboardDataNotifier(apiService);
    });

class DashboardDataNotifier extends StateNotifier<AsyncValue<DashboardData>> {
  final ApiService _apiService;

  DashboardDataNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.fetchDashboardData();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshDashboard() async {
    try {
      final data = await _apiService.fetchDashboardData();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      if (state.hasValue) {
        // Keep current dashboard data unchanged as per AT3
        // Rethrow so the view can catch it and display a snackbar/toast error message
        rethrow;
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}
