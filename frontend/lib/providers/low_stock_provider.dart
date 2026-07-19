import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/low_stock_product.dart';
import 'dashboard_provider.dart';

final lowStockProductsProvider = FutureProvider.autoDispose<List<LowStockProduct>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchLowStockProducts();
});
