import 'package:dio/dio.dart';
import '../models/dashboard_data.dart';

class ApiService {
  final Dio _dio;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

  Future<DashboardData> fetchDashboardData() async {
    try {
      final response = await _dio.get('/inventory/dashboard');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return DashboardData.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Không thể tải dữ liệu bảng điều khiển.');
        }
      } else {
        throw Exception('Không thể tải dữ liệu bảng điều khiển: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      String message = 'Lỗi kết nối máy chủ.';
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        message = 'Kết nối mạng quá hạn hoặc không thể kết nối. Vui lòng kiểm tra lại.';
      } else if (e.response != null && e.response?.data is Map) {
        message = e.response?.data['message'] ?? 'Lỗi từ phía máy chủ.';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }
}
