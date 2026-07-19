import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cashier_api_service.dart';

final cashierApiServiceProvider = Provider<CashierApiService>((ref) {
  return CashierApiService();
});

/// Increments whenever cashier invoice data changes so dashboard and shift
/// invoice screens reload from the same backend source.
final cashierDataVersionProvider = StateProvider<int>((ref) => 0);
