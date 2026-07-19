import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/staff_request.dart';
import 'api_service.dart';

/// Calls the Spring Boot API for the Manager Request Management feature.
///
/// Flutter does not access Supabase business tables directly.
/// Data flow:
/// Flutter -> Spring Boot -> Supabase PostgreSQL
class StaffRequestApiService {
  final Dio _dio;

  StaffRequestApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiService.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            final token =
                Supabase.instance.client.auth.currentSession?.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Supabase not initialized or no session
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> fetchStaffRequests({
    int page = 0,
    int size = 10,
    String requestType = 'ALL',
    String status = 'ALL',
    String keyword = '',
  }) async {
    try {
      final response = await _dio.get(
        '/manager/staff-requests',
        queryParameters: {
          'page': page,
          'size': size,
          'requestType': requestType,
          'status': status,
          'keyword': keyword.trim(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load staff requests: HTTP ${response.statusCode}',
        );
      }

      final body = _readResponseBody(response.data);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Failed to load staff requests.',
        );
      }

      final rawData = body['data'];

      if (rawData is! Map) {
        throw Exception('Invalid staff request data.');
      }

      final data = Map<String, dynamic>.from(rawData);
      final rawItems = data['items'] as List? ?? [];

      final items = rawItems
          .whereType<Map>()
          .map((item) => StaffRequest.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return {
        'items': items,
        'page': _parseInt(data['page'], page),
        'size': _parseInt(data['size'], size),
        'totalItems': _parseInt(data['totalItems'], 0),
        'totalPages': _parseInt(data['totalPages'], 0),
      };
    } on DioException catch (error) {
      throw Exception(
        _handleDioError(
          error,
          fallbackMessage: 'Unable to load staff requests.',
        ),
      );
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateStaffRequestStatus({
    required int requestNumber,
    required String requestType,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/manager/staff-requests/$requestNumber/status',
        data: {
          'requestType': requestType.toUpperCase(),
          'status': status.toUpperCase(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update staff request: HTTP ${response.statusCode}',
        );
      }

      final body = _readResponseBody(response.data);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Failed to update staff request.',
        );
      }
    } on DioException catch (error) {
      throw Exception(
        _handleDioError(
          error,
          fallbackMessage: 'Unable to update staff request.',
        ),
      );
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> adjustClearanceRequest({
    required int requestNumber,
    required double discountPercentage,
    required String reason,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/promotions/$requestNumber',
        data: {
          'discountValue': discountPercentage,
          'description': reason,
          'status': status.toUpperCase(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to adjust clearance request: HTTP ${response.statusCode}',
        );
      }

      final body = _readResponseBody(response.data);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Failed to adjust clearance request.',
        );
      }
    } on DioException catch (error) {
      throw Exception(
        _handleDioError(
          error,
          fallbackMessage: 'Unable to adjust clearance request.',
        ),
      );
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> adjustPurchaseRequest({
    required int requestNumber,
    required String? expectedDeliveryDate,
    required String status,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.put(
        '/purchase-requests/$requestNumber/adjust',
        data: {
          'expectedDeliveryDate': expectedDeliveryDate,
          'status': status.toUpperCase(),
          'items': items,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to adjust purchase request: HTTP ${response.statusCode}',
        );
      }

      final body = _readResponseBody(response.data);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Failed to adjust purchase request.',
        );
      }
    } on DioException catch (error) {
      throw Exception(
        _handleDioError(
          error,
          fallbackMessage: 'Unable to adjust purchase request.',
        ),
      );
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Map<String, dynamic> _readResponseBody(dynamic responseData) {
    if (responseData is! Map) {
      throw Exception('Invalid response from the server.');
    }

    return Map<String, dynamic>.from(responseData);
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _handleDioError(
    DioException error, {
    required String fallbackMessage,
  }) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the server. Please try again.';
    }

    final responseData = error.response?.data;

    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }

    if (error.response?.statusCode != null) {
      return 'Server error: HTTP ${error.response!.statusCode}.';
    }

    return fallbackMessage;
  }
}
