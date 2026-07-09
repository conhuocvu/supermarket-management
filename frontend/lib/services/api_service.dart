import 'package:dio/dio.dart';
import 'package:frontend/core/errors/app_error.dart';
import 'package:frontend/models/employee.dart';
import 'package:frontend/models/shift.dart';

class ApiService {
  final Dio _dio;
  final String Function()? _tokenProvider;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  ApiService({Dio? dio, String Function()? tokenProvider})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _defaultBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )),
        _tokenProvider = tokenProvider {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_tokenProvider != null) {
          final token = _tokenProvider!();
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
    ));
  }

  Future<Result<String>> getMockToken(String role) async {
    try {
      final response = await _dio.get('/auth/token', queryParameters: {'role': role});
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(apiResponse['data'] as String);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch mock token.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<List<Employee>>> getEmployees({String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/employees', queryParameters: queryParams);
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => Employee.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch employees.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<Employee>> getEmployee(int id) async {
    try {
      final response = await _dio.get('/employees/$id');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final employee = Employee.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(employee);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch employee details.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<Map<String, dynamic>>> getStats() async {
    try {
      final response = await _dio.get('/employees/stats');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(apiResponse['data'] as Map<String, dynamic>);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch stats.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<Employee>> hireEmployee({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String role,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post('/employees', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'role': role,
        'imageUrl': imageUrl ?? '',
      });
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final employee = Employee.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(employee);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to hire employee.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<Employee>> updateRole(int employeeId, String role) async {
    try {
      final response = await _dio.patch('/employees/$employeeId/role', data: {
        'role': role,
      });
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final employee = Employee.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(employee);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to update employee role.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  Future<Result<Shift>> assignShift(
    int employeeId, {
    required DateTime date,
    required String startTime,
    required String endTime,
    required String shiftType,
    String? register,
  }) async {
    try {
      final formattedDate = date.toIso8601String().substring(0, 10);
      final response = await _dio.post('/employees/$employeeId/shifts', data: {
        'date': formattedDate,
        'startTime': '$startTime:00',
        'endTime': '$endTime:00',
        'shiftType': shiftType,
        'register': register,
      });
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final shift = Shift.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(shift);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to assign shift.',
        ));
      }
    } on DioException catch (e) {
      return Result.failure(_handleDioException(e));
    } catch (e) {
      return Result.failure(AppError(
        code: ErrorCode.INTERNAL,
        userMessage: 'An unexpected error occurred: $e',
      ));
    }
  }

  AppError _handleDioException(DioException e) {
    bool retryable = false;
    ErrorCode code = ErrorCode.NETWORK;
    String message = 'Kết nối mạng không ổn định. Vui lòng thử lại.';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      retryable = true;
      code = ErrorCode.TIMEOUT;
      message = 'Hết thời gian chờ kết nối. Vui lòng kiểm tra lại.';
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      if (statusCode == 422 && data is Map && data['success'] == false) {
        final errors = data['data'];
        Map<String, String>? fieldErrors;
        if (errors is Map) {
          fieldErrors = errors.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        return AppError(
          code: ErrorCode.VALIDATION,
          userMessage: data['message'] ?? 'Dữ liệu nhập vào không hợp lệ.',
          fieldErrors: fieldErrors,
        );
      } else if (statusCode == 400 && data is Map && data['success'] == false) {
        return AppError(
          code: ErrorCode.VALIDATION,
          userMessage: data['message'] ?? 'Yêu cầu không hợp lệ.',
        );
      } else if (statusCode == 401) {
        return AppError(
          code: ErrorCode.AUTHENTICATION_REQUIRED,
          userMessage: 'Phiên làm việc hết hạn. Vui lòng đăng nhập lại.',
        );
      } else if (statusCode == 403) {
        return AppError(
          code: ErrorCode.PERMISSION_DENIED,
          userMessage: 'Bạn không có quyền thực hiện hành động này.',
        );
      } else if (statusCode == 404) {
        return AppError(
          code: ErrorCode.NOT_FOUND,
          userMessage: 'Không tìm thấy tài nguyên yêu cầu.',
        );
      }

      code = ErrorCode.INTERNAL;
      message = (data is Map ? data['message'] : null) ?? 'Lỗi máy chủ (HTTP $statusCode).';
    }

    return AppError(
      code: code,
      userMessage: message,
      retryable: retryable,
    );
  }
}
