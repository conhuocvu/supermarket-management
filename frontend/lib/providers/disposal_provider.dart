import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/disposal_form_data.dart';
import 'dashboard_provider.dart';

final disposalFormDataProvider = FutureProvider.autoDispose
    .family<DisposalFormData, int>((ref, stockInDetailNumber) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchDisposalFormData(stockInDetailNumber);
});
