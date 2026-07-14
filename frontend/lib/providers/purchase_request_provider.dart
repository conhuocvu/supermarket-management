import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_request.dart';
import 'dashboard_provider.dart';

final purchaseRequestsProvider = FutureProvider.autoDispose<List<PurchaseRequestList>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchPurchaseRequests();
});
