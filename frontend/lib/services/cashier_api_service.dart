import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cashier_models.dart';
import 'api_service.dart';

class CashierApiService {
  final Dio _dio;

  CashierApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiService.baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
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

  Future<CashierDashboardData> dashboard(String cashierId) async {
    final body = await _request(
      () => _dio.get('/cashier/dashboard', queryParameters: {'cashierId': cashierId}),
    );
    return CashierDashboardData.fromJson(_map(body['data']));
  }

  Future<List<CashierCategory>> categories() async {
    final body = await _request(() => _dio.get('/cashier/categories'));
    return (body['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => CashierCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CashierProduct>> products({
    String keyword = '',
    int? categoryNumber,
  }) async {
    final body = await _request(
      () => _dio.get(
        '/cashier/products',
        queryParameters: {
          'keyword': keyword.trim(),
          if (categoryNumber != null) 'categoryNumber': categoryNumber,
        },
      ),
    );
    return (body['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => CashierProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CashierInvoice> createInvoice(String cashierId) async {
    final body = await _request(
      () => _dio.post('/cashier/invoices', data: {'cashierId': cashierId}),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> startInvoice({
    required String cashierId,
    required int productNumber,
    double quantity = 1,
  }) async {
    final body = await _request(
      () => _dio.post(
        '/cashier/invoices/start',
        data: {
          'cashierId': cashierId,
          'productNumber': productNumber,
          'quantity': quantity,
        },
      ),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> invoice(int invoiceNumber) async {
    final body = await _request(
      () => _dio.get('/cashier/invoices/$invoiceNumber'),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> addItem(
    int invoiceNumber,
    int productNumber, {
    double quantity = 1,
  }) async {
    final body = await _request(
      () => _dio.post(
        '/cashier/invoices/$invoiceNumber/items',
        data: {'productNumber': productNumber, 'quantity': quantity},
      ),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> updateItem(
    int invoiceNumber,
    int detailId,
    double quantity,
  ) async {
    final body = await _request(
      () => _dio.patch(
        '/cashier/invoices/$invoiceNumber/items/$detailId',
        data: {'quantity': quantity},
      ),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> removeItem(int invoiceNumber, int detailId) async {
    final body = await _request(
      () => _dio.delete('/cashier/invoices/$invoiceNumber/items/$detailId'),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> cancelInvoice(int invoiceNumber) async {
    final body = await _request(
      () => _dio.patch('/cashier/invoices/$invoiceNumber/cancel'),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<CashierCustomer> searchCustomer(String phone) async {
    final body = await _request(
      () => _dio.get('/cashier/customers/search', queryParameters: {'phone': phone}),
    );
    return CashierCustomer.fromJson(_map(body['data']));
  }

  Future<CashierCustomer> registerCustomer(String fullName, String phone) async {
    final body = await _request(
      () => _dio.post(
        '/cashier/customers',
        data: {'fullName': fullName.trim(), 'phone': phone.trim()},
      ),
    );
    return CashierCustomer.fromJson(_map(body['data']));
  }

  Future<CashierInvoice> linkCustomer(
    int invoiceNumber,
    int? customerNumber,
  ) async {
    final body = await _request(
      () => _dio.patch(
        '/cashier/invoices/$invoiceNumber/customer',
        data: {'customerNumber': customerNumber},
      ),
    );
    return CashierInvoice.fromJson(_map(body['data']));
  }

  Future<List<CashierPromotion>> promotions(int invoiceNumber) async {
    final body = await _request(
      () => _dio.get('/cashier/invoices/$invoiceNumber/promotions'),
    );
    return (body['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => CashierPromotion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CheckoutPreview> previewCheckout({
    required int invoiceNumber,
    int? customerNumber,
    int? promotionNumber,
    int rewardPoints = 0,
  }) async {
    final body = await _request(
      () => _dio.post(
        '/cashier/invoices/$invoiceNumber/checkout-preview',
        data: {
          'customerNumber': customerNumber,
          'promotionNumber': promotionNumber,
          'rewardPoints': rewardPoints,
        },
      ),
    );
    return CheckoutPreview.fromJson(_map(body['data']));
  }

  Future<CashierReceipt> processPayment({
    required int invoiceNumber,
    int? customerNumber,
    int? promotionNumber,
    int rewardPoints = 0,
    required String paymentMethod,
    required double paidAmount,
  }) async {
    final body = await _request(
      () => _dio.post(
        '/cashier/invoices/$invoiceNumber/payment',
        data: {
          'customerNumber': customerNumber,
          'promotionNumber': promotionNumber,
          'rewardPoints': rewardPoints,
          'paymentMethod': paymentMethod,
          'paidAmount': paidAmount,
        },
      ),
    );
    return CashierReceipt.fromJson(_map(body['data']));
  }

  Future<CashierReceipt> receipt(int invoiceNumber) async {
    final body = await _request(
      () => _dio.get('/cashier/invoices/$invoiceNumber/receipt'),
    );
    return CashierReceipt.fromJson(_map(body['data']));
  }

  Future<ShiftInvoicePage> shiftInvoices({
    required String cashierId,
    int page = 0,
    int size = 10,
    String keyword = '',
    String status = 'ALL',
  }) async {
    final body = await _request(
      () => _dio.get(
        '/cashier/shift-invoices',
        queryParameters: {
          'cashierId': cashierId,
          'page': page,
          'size': size,
          'keyword': keyword.trim(),
          'status': status,
        },
      ),
    );
    return ShiftInvoicePage.fromJson(_map(body['data']));
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<dynamic>> Function() action,
  ) async {
    try {
      final response = await action();
      final body = _map(response.data);
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Request failed.');
      }
      return body;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw Exception('Cannot connect to the backend server.');
      }
      throw Exception('Unable to complete the request.');
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Invalid response from the server.');
  }
}
