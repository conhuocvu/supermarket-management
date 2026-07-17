import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../models/dashboard_data.dart';
import '../models/manager_dashboard_data.dart';
import '../models/category_item.dart';
import '../models/inventory_product.dart';
import '../models/inventory_product_detail.dart';
import '../models/product_adjustment.dart';
import '../models/inventory_transaction.dart';
import '../models/pending_task.dart';
import '../models/purchase_request.dart';

class ApiService {
  final Dio _dio;
  static const String mockUserUuid = 'e3b3ec4a-da0b-40f5-9747-29361993892b';

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
            body['message'] ?? 'Failed to load dashboard data.',
          );
        }
      } else {
        throw Exception(
          'Failed to load dashboard data: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<ManagerDashboardData> fetchManagerDashboardData() async {
    try {
      final response = await _dio.get('/manager/dashboard');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return ManagerDashboardData.fromJson(body['data']);
        } else {
          throw Exception(
            body['message'] ?? 'Failed to load manager dashboard data.',
          );
        }
      } else {
        throw Exception(
          'Failed to load manager dashboard data: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<InventoryTransaction>> fetchInventoryTransactions() async {
    try {
      final response = await _dio.get('/inventory/transactions');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => InventoryTransaction.fromJson(item)).toList();
        } else {
          throw Exception(body['message'] ?? 'Failed to load transactions.');
        }
      } else {
        throw Exception('Failed to load transactions: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<PendingTasks> fetchPendingTasks() async {
    try {
      final response = await _dio.get('/inventory/pending-tasks');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return PendingTasks.fromJson(body['data'] ?? {});
        } else {
          throw Exception(body['message'] ?? 'Failed to load pending tasks.');
        }
      } else {
        throw Exception('Failed to load pending tasks: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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
            body['message'] ?? 'Failed to load products list.',
          );
        }
      } else {
        throw Exception(
          'Failed to load products list: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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
          throw Exception(body['message'] ?? 'Failed to load categories.');
        }
      } else {
        throw Exception('Failed to load categories: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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
          response.data['message'] ?? 'Failed to update status.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> createPurchaseRequest(List<int> productNumbers) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
      final response = await _dio.post(
        '/purchase-requests/items',
        data: {
          'userId': userId,
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
            body['message'] ?? 'Failed to load units.',
          );
        }
      } else {
        throw Exception(
          'Failed to load units: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSuppliers() async {
    try {
      final response = await _dio.get('/inventory/suppliers');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          throw Exception(
            body['message'] ?? 'Failed to load suppliers list.',
          );
        }
      } else {
        throw Exception(
          'Failed to load suppliers: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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
          throw Exception(body['message'] ?? 'Failed to upload image.');
        }
      } else {
        throw Exception('Failed to upload image: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/inventory/products', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to add product.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/inventory/products/$id', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to update product.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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

  // ==========================================
  // Stock-In Methods
  // ==========================================

  Future<Map<String, dynamic>> fetchStockInFormData(int prNumber, int? supplierNumber) async {
    try {
      final response = await _dio.get(
        '/stock-ins/form-data',
        queryParameters: {
          'purchaseRequestNumber': prNumber,
          'supplierNumber': ?supplierNumber,
        },
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Failed to load stock-in form data.');
        }
      } else {
        throw Exception('Failed to load stock-in form data: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> compareStockInQuantities(
    int prNumber,
    int? supplierNumber,
    Map<int, double> deliveredQuantities,
  ) async {
    try {
      // Convert map keys to string as JSON map keys must be strings
      final stringKeysMap = deliveredQuantities.map((k, v) => MapEntry(k.toString(), v));
      final response = await _dio.post(
        '/stock-ins/compare-quantities',
        data: {
          'purchaseRequestNumber': prNumber,
          'supplierNumber': ?supplierNumber,
          'deliveredQuantities': stringKeysMap,
        },
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Failed to compare quantities.');
        }
      } else {
        throw Exception('Failed to compare quantities: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> saveDeliveryIssue({
    required int purchaseRequestNumber,
    required int productNumber,
    required String issueType,
    required double quantity,
    required String description,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
      final response = await _dio.post(
        '/inventory/delivery-issues',
        data: {
          'purchaseRequestNumber': purchaseRequestNumber,
          'productNumber': productNumber,
          'reportedBy': userId,
          'issueType': issueType,
          'quantity': quantity,
          'description': description,
        },
      );
      return response.statusCode == 201 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> submitStockIn(Map<String, dynamic> stockInPayload) async {
    try {
      final response = await _dio.post(
        '/stock-ins',
        data: stockInPayload,
      );
      return response.statusCode == 201 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Stock-Out Methods
  // ==========================================

  Future<Map<String, dynamic>> fetchStockOutFormData(int reportNumber) async {
    try {
      final response = await _dio.get(
        '/stock-outs/form-data',
        queryParameters: {'reportNumber': reportNumber},
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        } else {
          throw Exception(body['message'] ?? 'Failed to load stock-out form data.');
        }
      } else {
        throw Exception('Failed to load stock-out form data: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> submitStockOut(Map<String, dynamic> stockOutPayload) async {
    try {
      final response = await _dio.post(
        '/stock-outs',
        data: stockOutPayload,
      );
      return response.statusCode == 201 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<PurchaseRequestList>> fetchPurchaseRequests() async {
    try {
      final response = await _dio.get('/purchase-requests');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => PurchaseRequestList.fromJson(item)).toList();
        } else {
          throw Exception(body['message'] ?? 'Failed to load purchase requests.');
        }
      } else {
        throw Exception('Failed to load purchase requests: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<PurchaseRequestDetail> fetchPurchaseRequestDetail(int prNumber) async {
    try {
      final response = await _dio.get('/purchase-requests/$prNumber');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return PurchaseRequestDetail.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to load purchase request details.');
        }
      } else {
        throw Exception('Failed to load purchase request details: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> submitPurchaseRequestForApproval(int prNumber) async {
    try {
      final response = await _dio.post('/purchase-requests/$prNumber/submit');
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Staff Methods
  // ==========================================

  Future<Map<String, dynamic>> fetchStaffList({
    String? keyword,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/staff',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final itemsList = (data['staff'] as List? ?? [])
              .map((item) => _parseStaffMember(item as Map<String, dynamic>))
              .toList();
          return {
            'staff': itemsList,
            'totalStaff': (data['totalStaff'] as num?)?.toInt() ?? 0,
            'onShiftCount': (data['onShiftCount'] as num?)?.toInt() ?? 0,
          };
        } else {
          throw Exception(body['message'] ?? 'Failed to load staff list.');
        }
      } else {
        throw Exception('Failed to load staff list: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  dynamic _parseStaffMember(Map<String, dynamic> json) {
    // We return the raw map; the provider imports StaffMember and calls fromJson
    return json;
  }

  /// UC-ST-02: Fetch detailed information of a single staff member.
  Future<Map<String, dynamic>> fetchStaffDetail(String userId) async {
    try {
      final response = await _dio.get('/staff/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Staff record not found.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// UC-ST-03: Update a staff member's role.
  Future<void> setStaffRole(String userId, int roleNumber, {String? reason}) async {
    try {
      final response = await _dio.put('/staff/$userId/role', data: {
        'roleNumber': roleNumber,
        if (reason != null) 'reason': reason,
      });
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Unable to update staff role.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// UC-ST-04: Assign weekly shifts for a staff member.
  Future<void> assignStaffShifts(String userId, List<Map<String, dynamic>> schedule) async {
    try {
      final response = await _dio.post('/staff/$userId/shifts', data: {
        'schedule': schedule,
      });
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Unable to save shift assignment.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch all available roles.
  Future<List<Map<String, dynamic>>> fetchRoles() async {
    try {
      final response = await _dio.get('/staff/meta/roles');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((r) => r as Map<String, dynamic>)
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load roles.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch all available shifts.
  Future<List<Map<String, dynamic>>> fetchShifts() async {
    try {
      final response = await _dio.get('/staff/meta/shifts');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((r) => r as Map<String, dynamic>)
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load shifts.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
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

  // ==========================================
  // Category Methods
  // ==========================================

  Future<Map<String, dynamic>> getCategories({
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final response = await _dio.get(
        '/categories',
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> updateCategoryStatus(int categoryNumber, String status) async {
    try {
      await _dio.patch(
        '/categories/$categoryNumber/status',
        data: {'status': status},
      );
    } catch (e) {
      throw Exception('Failed to update category status: $e');
    }
  }

  Future<Map<String, dynamic>> getCategoryById(int categoryNumber) async {
    try {
      final response = await _dio.get('/categories/$categoryNumber');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      throw Exception('Failed to load category.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/categories', data: data);
      if (response.statusCode != 201 && response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to create category.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateCategory(int categoryNumber, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/categories/$categoryNumber', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update category.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }
}
