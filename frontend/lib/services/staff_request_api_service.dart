import 'package:dio/dio.dart';

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
      );

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

      if (response.data is! Map) {
        throw Exception('Invalid response from the server.');
      }

      final body = Map<String, dynamic>.from(response.data as Map);

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
      throw Exception(_handleDioError(error));
    } catch (error) {
      throw Exception(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _handleDioError(DioException error) {
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

    return 'Unable to load staff requests.';
  }
}
