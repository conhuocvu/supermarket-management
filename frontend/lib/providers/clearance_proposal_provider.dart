import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clearance_proposal.dart';
import '../models/promotion.dart';
import 'dashboard_provider.dart';

final clearanceProposalProvider = FutureProvider.autoDispose
    .family<ClearanceProposalData, int>((ref, stockInDetailNumber) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchClearanceProposalData(stockInDetailNumber);
});

final submittedClearanceProposalsProvider = FutureProvider.autoDispose<List<Promotion>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchSubmittedClearanceProposals();
});
