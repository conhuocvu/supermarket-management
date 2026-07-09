import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/employee.dart';
import 'package:frontend/models/shift.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/core/errors/app_error.dart';

// Provide a vanilla ApiService (no interceptor using token provider to prevent circular reference)
final vanillaApiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provide current user role simulation state
final currentUserRoleProvider = StateProvider<String>((ref) => 'MANAGER');

// FutureProvider that fetches the mock JWT token whenever role changes
final mockTokenProvider = FutureProvider<String>((ref) async {
  final role = ref.watch(currentUserRoleProvider);
  final vanillaApi = ref.read(vanillaApiServiceProvider);
  final result = await vanillaApi.getMockToken(role);
  return result.dataOrThrow;
});

// Provide ApiService configured with the mock JWT token
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    tokenProvider: () {
      final tokenAsync = ref.read(mockTokenProvider);
      return tokenAsync.value ?? '';
    },
  );
});

// Provide search query state
final employeeSearchQueryProvider = StateProvider<String>((ref) => '');

// Provide status filter state (ALL, ON_DUTY, OFF_DUTY, ON_LEAVE)
final employeeStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

// AsyncNotifier for the list of employees, also manages creation, role updates, and shift assignments.
class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() async {
    // Force wait until the mock JWT token is retrieved
    await ref.watch(mockTokenProvider.future);

    final api = ref.watch(apiServiceProvider);
    final search = ref.watch(employeeSearchQueryProvider);
    final status = ref.watch(employeeStatusFilterProvider);

    final result = await api.getEmployees(search: search, status: status);
    return result.dataOrThrow;
  }

  Future<Result<Employee>> hireEmployee({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String role,
    String? imageUrl,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.hireEmployee(
      name: name,
      email: email,
      phone: phone,
      location: location,
      role: role,
      imageUrl: imageUrl,
    );
    if (result.isSuccess) {
      ref.invalidate(employeeStatsProvider);
      ref.invalidateSelf();
    }
    return result;
  }

  Future<Result<Employee>> updateRole(int employeeId, String role) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.updateRole(employeeId, role);
    if (result.isSuccess) {
      ref.invalidate(employeeDetailProvider(employeeId));
      ref.invalidate(employeeStatsProvider);
      ref.invalidateSelf();
    }
    return result;
  }

  Future<Result<Shift>> assignShift(
    int employeeId, {
    required DateTime date,
    required String startTime,
    required String endTime,
    required String shiftType,
    String? register,
  }) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.assignShift(
      employeeId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      shiftType: shiftType,
      register: register,
    );
    if (result.isSuccess) {
      ref.invalidate(employeeDetailProvider(employeeId));
      ref.invalidate(employeeStatsProvider);
      ref.invalidateSelf();
    }
    return result;
  }
}

final employeesProvider = AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(() {
  return EmployeesNotifier();
});

// FutureProvider for dashboard stats
final employeeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  await ref.watch(mockTokenProvider.future);
  final api = ref.watch(apiServiceProvider);
  final result = await api.getStats();
  return result.dataOrThrow;
});

// FutureProvider for single employee details (family)
final employeeDetailProvider = FutureProvider.family<Employee, int>((ref, id) async {
  await ref.watch(mockTokenProvider.future);
  final api = ref.watch(apiServiceProvider);
  final result = await api.getEmployee(id);
  return result.dataOrThrow;
});
