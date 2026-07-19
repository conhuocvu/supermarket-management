import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clearance_proposal.dart';
import 'dashboard_provider.dart';

final clearanceProposalProvider = FutureProvider.autoDispose
    .family<ClearanceProposalData, int>((ref, stockInDetailNumber) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchClearanceProposalData(stockInDetailNumber);
});
