import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/errors/app_error.dart';
import 'package:frontend/models/employee.dart';
import 'package:frontend/models/shift.dart';
import 'package:frontend/models/promotion.dart';
import 'package:frontend/models/supplier.dart';
import 'package:frontend/models/product.dart';
import 'package:frontend/models/supplier_product.dart';
import '../models/dashboard_data.dart';
import '../models/category_item.dart';
import '../models/inventory_product.dart';
import '../models/inventory_product_detail.dart';
import '../models/product_adjustment.dart';

class ApiService {
  final Dio _dio;
  final String Function()? _tokenProvider;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  ApiService({Dio? dio, String Function()? tokenProvider})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
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

  // --- Mock Auth ---
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

  // --- Employee Management ---
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

  // --- Promotion Management ---
  Future<Result<List<Promotion>>> getPromotions({String? search, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _dio.get('/promotions', queryParameters: queryParams);
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => Promotion.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch promotions.',
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

  Future<Result<Promotion>> getPromotion(int id) async {
    try {
      final response = await _dio.get('/promotions/$id');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final promotion = Promotion.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(promotion);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch promotion details.',
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

  Future<Result<Promotion>> createPromotion({
    required String name,
    required String code,
    required String priority,
    required String discountType,
    required double discountValue,
    String? description,
    List<String>? targetCategories,
    List<String>? targetProducts,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? visibility,
  }) async {
    try {
      final response = await _dio.post('/promotions', data: {
        'name': name,
        'code': code,
        'priority': priority,
        'discountType': discountType,
        'discountValue': discountValue,
        'description': description ?? '',
        'targetCategories': targetCategories ?? [],
        'targetProducts': targetProducts ?? [],
        'startDate': startDate.toIso8601String().substring(0, 10),
        'endDate': endDate.toIso8601String().substring(0, 10),
        'imageUrl': imageUrl ?? '',
        'visibility': visibility ?? 'Storewide & Online',
      });
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final promotion = Promotion.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(promotion);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to create promotion.',
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

  Future<Result<Promotion>> updatePromotion(
    int id, {
    required String name,
    required String code,
    required String priority,
    required String discountType,
    required double discountValue,
    String? description,
    List<String>? targetCategories,
    List<String>? targetProducts,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? visibility,
  }) async {
    try {
      final response = await _dio.put('/promotions/$id', data: {
        'name': name,
        'code': code,
        'priority': priority,
        'discountType': discountType,
        'discountValue': discountValue,
        'description': description ?? '',
        'targetCategories': targetCategories ?? [],
        'targetProducts': targetProducts ?? [],
        'startDate': startDate.toIso8601String().substring(0, 10),
        'endDate': endDate.toIso8601String().substring(0, 10),
        'imageUrl': imageUrl ?? '',
        'visibility': visibility ?? 'Storewide & Online',
      });
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final promotion = Promotion.fromJson(apiResponse['data'] as Map<String, dynamic>);
        return Result.success(promotion);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to update promotion.',
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

  Future<Result<void>> deletePromotion(int id) async {
    try {
      final response = await _dio.delete('/promotions/$id');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(null);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to delete promotion.',
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

  // --- Supplier Management ---
  Future<Result<List<Supplier>>> getSuppliers({String? search, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _dio.get('/suppliers', queryParameters: queryParams);
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch suppliers.',
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

  Future<Result<Supplier>> getSupplier(int id) async {
    try {
      final response = await _dio.get('/suppliers/$id');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(Supplier.fromJson(apiResponse['data'] as Map<String, dynamic>));
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch supplier details.',
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

  Future<Result<Supplier>> createSupplier({
    required String code,
    required String name,
    required String category,
    required String nextDelivery,
    required String status,
    required String contactType,
    required String contactValue,
    required double onTimeDeliveryRate,
    required double averageRating,
    required String notes,
    required String certification,
  }) async {
    try {
      final response = await _dio.post(
        '/suppliers',
        data: {
          'code': code,
          'name': name,
          'category': category,
          'nextDelivery': nextDelivery,
          'status': status,
          'contactType': contactType,
          'contactValue': contactValue,
          'onTimeDeliveryRate': onTimeDeliveryRate,
          'averageRating': averageRating,
          'notes': notes,
          'certification': certification,
        },
      );
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(Supplier.fromJson(apiResponse['data'] as Map<String, dynamic>));
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to create supplier.',
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

  Future<Result<Supplier>> updateSupplier(
    int id, {
    required String code,
    required String name,
    required String category,
    required String nextDelivery,
    required String status,
    required String contactType,
    required String contactValue,
    required double onTimeDeliveryRate,
    required double averageRating,
    required String notes,
    required String certification,
  }) async {
    try {
      final response = await _dio.put(
        '/suppliers/$id',
        data: {
          'code': code,
          'name': name,
          'category': category,
          'nextDelivery': nextDelivery,
          'status': status,
          'contactType': contactType,
          'contactValue': contactValue,
          'onTimeDeliveryRate': onTimeDeliveryRate,
          'averageRating': averageRating,
          'notes': notes,
          'certification': certification,
        },
      );
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(Supplier.fromJson(apiResponse['data'] as Map<String, dynamic>));
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to update supplier.',
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

  Future<Result<Supplier>> updateSupplierStatus(int id, String status) async {
    try {
      final response = await _dio.patch(
        '/suppliers/$id/status',
        data: {'status': status},
      );
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        return Result.success(Supplier.fromJson(apiResponse['data'] as Map<String, dynamic>));
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to update status.',
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

  Future<Result<List<Product>>> getProducts({String? search, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _dio.get('/products', queryParameters: queryParams);
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch products.',
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

  Future<Result<List<SupplierProduct>>> getSupplierProducts(int supplierId) async {
    try {
      final response = await _dio.get('/suppliers/$supplierId/products');
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => SupplierProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to fetch supplier products.',
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

  Future<Result<List<SupplierProduct>>> assignProducts(
    int supplierId,
    List<Map<String, dynamic>> assignments,
  ) async {
    try {
      final response = await _dio.post(
        '/suppliers/$supplierId/products',
        data: assignments,
      );
      final apiResponse = response.data as Map<String, dynamic>;

      if (apiResponse['success'] == true) {
        final list = (apiResponse['data'] as List)
            .map((e) => SupplierProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(list);
      } else {
        return Result.failure(AppError(
          code: ErrorCode.VALIDATION,
          userMessage: apiResponse['message'] ?? 'Failed to assign products.',
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

  // --- Inventory Management (from main branch) ---
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
          'userId': 'e3b3ec4a-da0b-40f5-9747-29361993892b', // Default Stock Controller UUID from database
          'productNumbers': productNumbers,
        },
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to add products to purchase request.',
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
                (item) => InventoryProduct.fromJson(item as Map<String, dynamic>),
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

  // --- Helper Error Handlers ---
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
