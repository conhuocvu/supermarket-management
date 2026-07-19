import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../models/dashboard_data.dart';
import '../models/manager_dashboard_data.dart';
import '../models/category_item.dart';
import '../models/inventory_product.dart';
import '../models/inventory_product_detail.dart';
import '../models/product_adjustment.dart';
import '../models/profile.dart';
import '../models/inventory_transaction.dart';
import '../models/pending_task.dart';
import '../models/purchase_request.dart';
import '../models/low_stock_product.dart';
import '../models/supplier_product.dart';
import '../models/expiring_product.dart';
import '../models/clearance_proposal.dart';
import '../models/promotion.dart';
import '../models/disposal_form_data.dart';
import '../models/product_report.dart';

class ApiService {
  final Dio _dio;
  static const String mockUserUuid = 'e3b3ec4a-da0b-40f5-9747-29361993892b';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  ApiService() : _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    // Attach the Supabase JWT Bearer token to every request so Spring Boot can
    // verify ownership (IDOR protection) without a separate auth step.
    dio.interceptors.add(
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
    return dio;
  }

  Future<DashboardData> fetchDashboardData() async {
    try {
      final response = await _dio.get('/inventory/dashboard');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return DashboardData.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to load dashboard data.');
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
          return data
              .map((item) => InventoryTransaction.fromJson(item))
              .toList();
        } else {
          throw Exception(body['message'] ?? 'Failed to load transactions.');
        }
      } else {
        throw Exception(
          'Failed to load transactions: HTTP ${response.statusCode}',
        );
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
        throw Exception(
          'Failed to load pending tasks: HTTP ${response.statusCode}',
        );
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
          throw Exception(body['message'] ?? 'Failed to load products list.');
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
        throw Exception(
          'Failed to load categories: HTTP ${response.statusCode}',
        );
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
        throw Exception(response.data['message'] ?? 'Failed to update status.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> createPurchaseRequest(List<int> productNumbers) async {
    try {
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
      final response = await _dio.post(
        '/purchase-requests/items',
        data: {'userId': userId, 'productNumbers': productNumbers},
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
          throw Exception(body['message'] ?? 'Failed to load units.');
        }
      } else {
        throw Exception('Failed to load units: HTTP ${response.statusCode}');
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
          throw Exception(body['message'] ?? 'Failed to load suppliers list.');
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

  // ---------------------------------------------------------------------------
  // Profile Methods
  // ---------------------------------------------------------------------------

  /// Fetches a profile via the Spring Boot backend (GET /api/profiles/{userId}).
  /// Converts the backend DTO field names (camelCase) into the Profile model.
  Future<Profile> fetchProfile(String userId) async {
    try {
      final response = await _dio.get('/profiles/$userId');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          // Backend DTO uses camelCase; map to snake_case for Profile.fromJson
          return Profile.fromJson({
            'user_id': data['userId'],
            'role_number': data['roleNumber'],
            'full_name': data['fullName'],
            'phone': data['phone'],
            'status': data['status'],
            'created_at': data['createdAt'],
            'avatar_url': data['avatarUrl'],
            'address': data['address'],
            'last_login': data['lastLogin'],
          });
        } else {
          throw Exception(body['message'] ?? 'Failed to load profile.');
        }
      } else {
        throw Exception('Failed to load profile: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Updates editable profile fields via the Spring Boot backend
  /// (PUT /api/profiles/{userId}).
  /// Returns the updated Profile so the caller can refresh local state
  /// without an extra fetch (fixes Issue #5 redundant refresh).
  Future<Profile> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? address,
  }) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _dio.put(
          '/profiles/$userId',
          data: {
            'fullName': fullName,
            'phone': phone,
            'address': address,
          },
        );
        if (response.statusCode == 200) {
          final body = response.data;
          if (body['success'] == true) {
            final data = body['data'] as Map<String, dynamic>;
            return Profile.fromJson({
              'user_id': data['userId'],
              'role_number': data['roleNumber'],
              'full_name': data['fullName'],
              'phone': data['phone'],
              'status': data['status'],
              'created_at': data['createdAt'],
              'avatar_url': data['avatarUrl'],
              'address': data['address'],
              'last_login': data['lastLogin'],
            });
          } else {
            throw Exception(body['message'] ?? 'Failed to update profile.');
          }
        } else {
          throw Exception('Failed to update profile: HTTP ${response.statusCode}');
        }
      } on DioException catch (e) {
        final isTransientError = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        if (attempt == 3 || !isTransientError) {
          throw Exception(_handleDioError(e));
        }
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      } catch (e) {
        if (attempt == 3) {
          throw Exception('Unexpected error occurred: $e');
        }
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
    throw Exception('Failed to update profile after multiple attempts.');
  }

  Future<String> uploadAvatar(String userId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Determine content-type from extension so the backend can validate it
      final ext = imageFile.name.split('.').last.toLowerCase();
      final mimeType = const {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      }[ext] ?? 'image/jpeg';

      // Build DioMediaType from mime string (e.g. "image/jpeg" → type="image", subtype="jpeg")
      final mimeParts = mimeType.split('/');
      final dioContentType = DioMediaType(mimeParts[0], mimeParts[1]);

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
          contentType: dioContentType,
        ),
      });

      final response = await _dio.put(
        '/profiles/$userId/avatar',
        data: formData,
        options: Options(
          // Avatar uploads may take longer than the default 30s
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return body['data']['avatarUrl'] as String;
        } else {
          throw Exception(body['message'] ?? 'Failed to upload avatar.');
        }
      } else {
        throw Exception('Failed to upload avatar: HTTP ${response.statusCode}');
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

  Future<Map<String, dynamic>> fetchStockInFormData(
    int prNumber,
    int? supplierNumber,
  ) async {
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
          throw Exception(
            body['message'] ?? 'Failed to load stock-in form data.',
          );
        }
      } else {
        throw Exception(
          'Failed to load stock-in form data: HTTP ${response.statusCode}',
        );
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
      final stringKeysMap = deliveredQuantities.map(
        (k, v) => MapEntry(k.toString(), v),
      );
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
        throw Exception(
          'Failed to compare quantities: HTTP ${response.statusCode}',
        );
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
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
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
      final response = await _dio.post('/stock-ins', data: stockInPayload);
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
          throw Exception(
            body['message'] ?? 'Failed to load stock-out form data.',
          );
        }
      } else {
        throw Exception(
          'Failed to load stock-out form data: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> submitStockOut(Map<String, dynamic> stockOutPayload) async {
    try {
      final response = await _dio.post('/stock-outs', data: stockOutPayload);
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
          return data
              .map((item) => PurchaseRequestList.fromJson(item))
              .toList();
        } else {
          throw Exception(
            body['message'] ?? 'Failed to load purchase requests.',
          );
        }
      } else {
        throw Exception(
          'Failed to load purchase requests: HTTP ${response.statusCode}',
        );
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
          throw Exception(
            body['message'] ?? 'Failed to load purchase request details.',
          );
        }
      } else {
        throw Exception(
          'Failed to load purchase request details: HTTP ${response.statusCode}',
        );
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

  Future<PurchaseRequestFormData> fetchPurchaseRequestFormData() async {
    try {
      final response = await _dio.get('/purchase-requests/form-data');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return PurchaseRequestFormData.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to load form data.');
        }
      } else {
        throw Exception('Failed to load form data: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<PurchaseRequestDetail> fetchOrCreateDraftPurchaseRequest() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
      final response = await _dio.get('/purchase-requests/draft', queryParameters: {'userId': userId});
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return PurchaseRequestDetail.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to load draft.');
        }
      } else {
        throw Exception('Failed to load draft: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<PurchaseRequestDetail> saveDraftPurchaseRequest(Map<String, dynamic> payload) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? mockUserUuid;
      final fullPayload = {
        'userId': userId,
        ...payload,
      };
      final response = await _dio.put('/purchase-requests/draft', data: fullPayload);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return PurchaseRequestDetail.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to save draft.');
        }
      } else {
        throw Exception('Failed to save draft: HTTP ${response.statusCode}');
      }
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
    int page = 0,
    int size = 6,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'size': size};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/staff', queryParameters: queryParams);
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
            'totalPages': (data['totalPages'] as num?)?.toInt() ?? 1,
          };
        } else {
          throw Exception(body['message'] ?? 'Failed to load staff list.');
        }
      } else {
        throw Exception(
          'Failed to load staff list: HTTP ${response.statusCode}',
        );
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
  Future<void> setStaffRole(String userId, int roleNumber) async {
    try {
      final response = await _dio.put(
        '/staff/$userId/role',
        data: {'roleNumber': roleNumber},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Unable to update staff role.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// UC-ST-04: Assign weekly shifts for a staff member.
  Future<void> assignStaffShifts(
    String userId,
    List<Map<String, dynamic>> schedule,
  ) async {
    try {
      final response = await _dio.post(
        '/staff/$userId/shifts',
        data: {'schedule': schedule},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Unable to save shift assignment.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
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

  /// Fetch promotions list with keyword, status filter, and pagination.
  Future<Map<String, dynamic>> fetchPromotions({
    String? keyword,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'size': size};
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/promotions',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to load promotions.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Upload promotion image.
  Future<void> uploadPromotionImage(
    int promotionNumber,
    List<int> bytes,
    String filename,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _dio.post(
        '/promotions/$promotionNumber/upload-image',
        data: formData,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Failed to upload image.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Fetch promotion detail by promotion number.
  Future<Map<String, dynamic>> fetchPromotionDetail(int promotionNumber) async {
    try {
      final response = await _dio.get('/promotions/$promotionNumber');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to load promotion detail.',
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new promotion.
  Future<Map<String, dynamic>> createPromotion(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/promotions', data: data);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to create promotion.',
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing promotion.
  Future<void> updatePromotion(
    int promotionNumber,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/promotions/$promotionNumber',
        data: data,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to update promotion.',
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Deactivate a promotion (sets status to INACTIVE).
  Future<void> deactivatePromotion(int promotionNumber) async {
    try {
      final response = await _dio.patch(
        '/promotions/$promotionNumber/deactivate',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(
        response.data['message'] ?? 'Failed to deactivate promotion.',
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<List<LowStockProduct>> fetchLowStockProducts() async {
    try {
      final response = await _dio.get('/inventory/low-stock');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => LowStockProduct.fromJson(item)).toList();
        } else {
          throw Exception(body['message'] ?? 'Failed to load low stock products.');
        }
      } else {
        throw Exception('Failed to load low stock products: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<ExpiringProduct>> fetchExpiringProducts({String? search, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }
      final response = await _dio.get('/inventory/expiring-products', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          final data = body['data'] as List? ?? [];
          return data.map((item) => ExpiringProduct.fromJson(item)).toList();
        } else {
          throw Exception(body['message'] ?? 'Failed to load expiring products.');
        }
      } else {
        throw Exception('Failed to load expiring products: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<ClearanceProposalData> fetchClearanceProposalData(int stockInDetailNumber) async {
    try {
      final response = await _dio.get('/promotions/clearance-proposals/$stockInDetailNumber');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return ClearanceProposalData.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Failed to load proposal data.');
        }
      } else {
        throw Exception('Failed to load proposal data: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> submitClearanceProposal({
    required int stockInDetailNumber,
    required int productNumber,
    required double discountPercentage,
    String? reason,
  }) async {
    try {
      final response = await _dio.post('/promotions/clearance-proposals', data: {
        'stockInDetailNumber': stockInDetailNumber,
        'productNumber': productNumber,
        'discountPercentage': discountPercentage,
        'reason': reason,
      });
      if (response.statusCode == 201) {
        final body = response.data;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Failed to submit proposal.');
        }
      } else {
        throw Exception('Failed to submit proposal: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<Promotion>> fetchSubmittedClearanceProposals() async {
    try {
      final response = await _dio.get('/promotions/clearance-proposals/submitted');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((item) => Promotion.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load submitted proposals: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<DisposalFormData> fetchDisposalFormData(int stockInDetailNumber) async {
    try {
      final response = await _dio.get('/inventory/disposals/$stockInDetailNumber');
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          return DisposalFormData.fromJson(body['data']);
        } else {
          throw Exception(body['message'] ?? 'Expired product information cannot be loaded.');
        }
      } else {
        throw Exception('Expired product information cannot be loaded.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Expired product information cannot be loaded.');
    }
  }

  Future<void> recordDisposal({
    required int stockInDetailNumber,
    required int productNumber,
    required double quantity,
    required String reason,
    String? observations,
  }) async {
    try {
      final response = await _dio.post('/stock-outs/disposals', data: {
        'stockInDetailNumber': stockInDetailNumber,
        'productNumber': productNumber,
        'quantity': quantity,
        'reason': reason,
        'observations': observations,
      });
      if (response.statusCode == 201) {
        final body = response.data;
        if (body['success'] != true) {
          throw Exception(body['message'] ?? 'Expired product cannot be disposed.');
        }
      } else {
        throw Exception('Expired product cannot be disposed.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Expired product cannot be disposed.');
    }
  }

  Future<List<ProductReport>> fetchProductReports({
    String? search,
    String? issueType,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (issueType != null && issueType.isNotEmpty && issueType != 'All') {
        queryParams['issueType'] = issueType;
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/inventory/product-reports', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List).map((item) => ProductReport.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Product report data cannot be loaded.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Product report data cannot be loaded.');
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
      final queryParams = <String, dynamic>{'page': page, 'size': size};

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
      if (response.statusCode != 201 && response.statusCode != 200 ||
          response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to create category.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateCategory(
    int categoryNumber,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/categories/$categoryNumber',
        data: data,
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to update category.',
        );
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Supplier Methods
  // ==========================================

  Future<Map<String, dynamic>> fetchSupplierList({
    String? keyword,
    String? status,
    int page = 0,
    int size = 6,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/suppliers',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to load suppliers.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSupplierDetail(int id) async {
    try {
      final response = await _dio.get('/suppliers/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['message'] ?? 'Failed to load supplier detail.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Creates a supplier and returns the new supplier number.
  Future<int> createSupplier(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/suppliers', data: data);
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data['success'] == true) {
        final supplierData = response.data['data'] as Map<String, dynamic>;
        return (supplierData['supplierNumber'] as num?)?.toInt() ?? 0;
      }
      throw Exception(response.data['message'] ?? 'Failed to create supplier.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateSupplier(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/suppliers/$id', data: data);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update supplier.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateSupplierStatus(int id, String status) async {
    try {
      final response = await _dio.patch(
        '/suppliers/$id/status',
        data: {'status': status},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update supplier status.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<List<SupplierProduct>> fetchSupplierProducts(int supplierNumber) async {
    try {
      final response = await _dio.get('/suppliers/$supplierNumber/products');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        return list.map((item) => SupplierProduct.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load supplier products.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> assignSupplierProducts(int supplierNumber, List<Map<String, dynamic>> assignments) async {
    try {
      final response = await _dio.post('/suppliers/$supplierNumber/products', data: assignments);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to assign products to supplier.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> updateSupplierImportPrices(int supplierNumber, List<Map<String, dynamic>> assignments) async {
    try {
      final response = await _dio.put('/suppliers/$supplierNumber/products/prices', data: assignments);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update import prices.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Work Schedule Methods
  // ==========================================

  /// A user's assigned shifts for a month
  /// (GET /api/work-schedules/{userId}?year=&month=).
  /// Each item: scheduleNumber, workDate, status (ASSIGNED | COMPLETED |
  /// CANCELLED | MISSED), shiftNumber, shiftName, startTime, endTime.
  Future<List<Map<String, dynamic>>> fetchWorkSchedules(
      String userId, int year, int month) async {
    try {
      final response = await _dio.get(
        '/work-schedules/$userId',
        queryParameters: {'year': year, 'month': month},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load work schedule.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Leave Request Methods
  // ==========================================

  /// A user's own leave requests (GET /api/leave-requests/{userId}).
  Future<List<Map<String, dynamic>>> fetchLeaveRequests(String userId) async {
    try {
      final response = await _dio.get('/leave-requests/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load leave requests.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Create a leave request (POST /api/leave-requests). Dates as ISO yyyy-MM-dd.
  Future<Map<String, dynamic>> createLeaveRequest({
    required String userId,
    required String reason,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.post('/leave-requests', data: {
        'userId': userId,
        'reason': reason,
        'startDate': startDate,
        'endDate': endDate,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create leave request.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Cancel a pending leave request
  /// (PUT /api/leave-requests/{leaveNumber}/cancel — sets status to CANCELLED).
  Future<void> cancelLeaveRequest(int leaveNumber, String userId) async {
    try {
      final response = await _dio.put(
        '/leave-requests/$leaveNumber/cancel',
        queryParameters: {'userId': userId},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to cancel leave request.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Shift Change Request Methods
  // ==========================================

  /// A user's shift change requests (GET /api/shift-change-requests/{userId}).
  Future<List<Map<String, dynamic>>> fetchShiftChangeRequests(String userId) async {
    try {
      final response = await _dio.get('/shift-change-requests/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load shift change requests.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Create a shift change request (POST /api/shift-change-requests).
  /// Sends structured fields for both current (from) and target (to) shift.
  Future<Map<String, dynamic>> createShiftChangeRequest({
    required String userId,
    String? reason,
    // Current shift
    required String currentShiftDate,
    required String currentShiftType,
    required String currentShiftStart,
    required String currentShiftEnd,
    // Target shift
    required String targetShiftDate,
    required String targetShiftType,
    required String targetShiftStart,
    required String targetShiftEnd,
  }) async {
    try {
      final response = await _dio.post('/shift-change-requests', data: {
        'userId': userId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'currentShiftDate': currentShiftDate,
        'currentShiftType': currentShiftType,
        'currentShiftStart': currentShiftStart,
        'currentShiftEnd': currentShiftEnd,
        'targetShiftDate': targetShiftDate,
        'targetShiftType': targetShiftType,
        'targetShiftStart': targetShiftStart,
        'targetShiftEnd': targetShiftEnd,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create shift change request.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }


  /// Cancel a pending shift change request
  /// (PUT /api/shift-change-requests/{requestNumber}/cancel).
  Future<void> cancelShiftChangeRequest(int requestNumber, String userId) async {
    try {
      final response = await _dio.put(
        '/shift-change-requests/$requestNumber/cancel',
        queryParameters: {'userId': userId},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to cancel shift change request.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Attendance Methods
  // ==========================================

  /// Fetch today's attendance record (GET /api/attendance/{userId}/today).
  /// Returns null if no record exists for today.
  Future<Map<String, dynamic>?> fetchTodayAttendance(String userId) async {
    try {
      final response = await _dio.get('/attendance/$userId/today');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      throw Exception(response.data['message'] ?? 'Failed to load attendance.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Check in to shift (POST /api/attendance/{userId}/check-in).
  Future<Map<String, dynamic>> checkIn(String userId) async {
    try {
      final response = await _dio.post('/attendance/$userId/check-in');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to check in.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Check out from shift (POST /api/attendance/{userId}/check-out).
  Future<Map<String, dynamic>> checkOut(String userId) async {
    try {
      final response = await _dio.post('/attendance/$userId/check-out');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to check out.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  // ==========================================
  // Notification Methods (Feature 5.1)
  // ==========================================

  /// A user's notifications, newest first (GET /api/notifications/{userId}).
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      final response = await _dio.get('/notifications/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load notifications.');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Marks one notification as read
  /// (PUT /api/notifications/{notificationNumber}/read).
  Future<void> markNotificationRead(int notificationNumber, String userId) async {
    try {
      final response = await _dio.put(
        '/notifications/$notificationNumber/read',
        queryParameters: {'userId': userId},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark notification as read.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  /// Marks all of the user's notifications as read
  /// (PUT /api/notifications/{userId}/read-all).
  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final response = await _dio.put('/notifications/$userId/read-all');
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark notifications as read.');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }
}
