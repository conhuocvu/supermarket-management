import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dashboard_data.dart';
import '../models/category_item.dart';
import '../models/inventory_product.dart';
import '../models/inventory_product_detail.dart';
import '../models/product_adjustment.dart';

class ApiService {
  final Dio _dio;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

  Future<DashboardData> fetchDashboardData() async {
    try {
      final response = await _dio.get('/inventory/dashboard');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return DashboardData.fromJson(body['data']);
        } else {
          throw Exception(
            body['message'] ?? 'Không thể tải dữ liệu bảng điều khiển.',
          );
        }
      } else {
        throw Exception(
          'Không thể tải dữ liệu bảng điều khiển: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<Map<String, dynamic>> fetchInventoryProducts({
    String? keyword,
    int? categoryNumber,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'size': size};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (categoryNumber != null) {
        queryParams['categoryNumber'] = categoryNumber;
      }

      final response = await _dio.get(
        '/inventory/products/search',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'];
          final itemsList = (data['items'] as List? ?? [])
              .map((item) => InventoryProduct.fromJson(item))
              .toList();
          return {
            'items': itemsList,
            'page': data['page'] ?? 0,
            'size': data['size'] ?? 10,
            'totalItems': data['totalItems'] ?? 0,
            'totalPages': data['totalPages'] ?? 0,
          };
        } else {
          throw Exception(
            body['message'] ?? 'Không thể tải danh sách sản phẩm.',
          );
        }
      } else {
        throw Exception(
          'Không thể tải danh sách sản phẩm: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<List<CategoryItem>> fetchCategories() async {
    try {
      final response = await _dio.get('/inventory/categories');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => CategoryItem.fromJson(item)).toList();
        } else {
          throw Exception(body['message'] ?? 'Không thể tải danh mục.');
        }
      } else {
        throw Exception('Không thể tải danh mục: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<void> updateProductStatus(int productNumber, String status) async {
    try {
      final response = await _dio.patch(
        '/inventory/products/$productNumber/status',
        queryParameters: {'status': status},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Không thể cập nhật trạng thái.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<void> createPurchaseRequest(List<int> productNumbers) async {
    try {
      final response = await _dio.post(
        '/purchase-requests/items',
        data: {
          'userId':
              'e3b3ec4a-da0b-40f5-9747-29361993892b', // Default Stock Controller UUID from database
          'productNumbers': productNumbers,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ??
              'Failed to add products to purchase request.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUnits() async {
    try {
      final response = await _dio.get('/inventory/units');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          throw Exception(
            body['message'] ?? 'Không thể tải danh sách đơn vị tính.',
          );
        }
      } else {
        throw Exception(
          'Không thể tải danh sách đơn vị tính: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<String> uploadProductImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: imageFile.name),
      });

      final response = await _dio.post(
        '/inventory/products/upload',
        data: formData,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data']['url'] as String;
        } else {
          throw Exception(body['message'] ?? 'Không thể tải ảnh lên.');
        }
      } else {
        throw Exception('Không thể tải ảnh lên: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/inventory/products', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Không thể thêm sản phẩm.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/inventory/products/$id', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Không thể cập nhật sản phẩm.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<void> deleteProduct(int productNumber) async {
    try {
      final response = await _dio.delete('/inventory/products/$productNumber');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to delete product.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<InventoryProduct>> fetchWarningProducts(
    String warningType,
  ) async {
    try {
      final response = await _dio.get(
        '/inventory/products/warnings',
        queryParameters: {'warningType': warningType},
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final itemsList = body['data']['items'] as List<dynamic>;
          return itemsList
              .map(
                (item) =>
                    InventoryProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      }
      throw Exception('Failed to load warning products.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<InventoryProductDetail> fetchProductDetails(int productNumber) async {
    try {
      final response = await _dio.get('/inventory/products/$productNumber');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return InventoryProductDetail.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to load product details.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<ProductAdjustmentData> fetchProductAdjustmentData(
    int productNumber,
  ) async {
    try {
      final response = await _dio.get(
        '/inventory/products/$productNumber/adjustment',
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return ProductAdjustmentData.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
      }
      throw Exception('Failed to load product adjustment data.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> adjustProductQuantity({
    required int productNumber,
    required String adjustmentType,
    required double quantity,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/inventory/products/$productNumber/adjustments',
        data: {
          'adjustmentType': adjustmentType,
          'quantity': quantity,
          'reason': reason,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  String _handleDioError(DioException e) {
    String message = 'Server connection error.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      message = 'Connection timeout or server unreachable. Please try again.';
    } else if (e.response != null && e.response?.data is Map) {
      message = e.response?.data['message'] ?? 'Server error.';
    }
    return message;
  }
}
