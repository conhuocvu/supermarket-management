import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expiring_product.dart';
import 'dashboard_provider.dart';

final expiringProductsProvider = FutureProvider.autoDispose
    .family<List<ExpiringProduct>, ({String search, String status})>(
  (ref, params) async {
    final apiService = ref.watch(apiServiceProvider);
    return await apiService.fetchExpiringProducts(
      search: params.search,
      status: params.status,
    );
  },
);
