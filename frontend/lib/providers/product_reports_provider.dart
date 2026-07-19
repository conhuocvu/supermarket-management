import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_report.dart';
import 'dashboard_provider.dart';

final productReportsProvider = FutureProvider.autoDispose
    .family<List<ProductReport>, ({String search, String issueType, String status})>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.fetchProductReports(
      search: params.search,
      issueType: params.issueType,
      status: params.status,
    );
  },
);
