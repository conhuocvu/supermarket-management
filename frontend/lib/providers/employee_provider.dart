import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/employee.dart';
import 'package:frontend/services/api_service.dart';

// Provide ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provide current user role simulation state
final currentUserRoleProvider = StateProvider<String>((ref) {
  final api = ref.watch(apiServiceProvider);
  return api.currentUserRole;
});

// Provide search query state
final employeeSearchQueryProvider = StateProvider<String>((ref) => '');

// Provide status filter state (ALL, ON_DUTY, OFF_DUTY, ON_LEAVE)
final employeeStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

// FutureProvider for the filtered list of employees
final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final search = ref.watch(employeeSearchQueryProvider);
  final status = ref.watch(employeeStatusFilterProvider);
  
  final result = await api.getEmployees(search: search, status: status);
  return result.dataOrThrow;
});

// FutureProvider for dashboard stats
final employeeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final result = await api.getStats();
  return result.dataOrThrow;
});

// FutureProvider for single employee details (family)
final employeeDetailProvider = FutureProvider.family<Employee, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final result = await api.getEmployee(id);
  return result.dataOrThrow;
});
