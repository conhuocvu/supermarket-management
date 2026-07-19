import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_transaction.dart';
import '../models/pending_task.dart';
import 'dashboard_provider.dart';

final inventoryTransactionsProvider = FutureProvider.autoDispose<List<InventoryTransaction>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchInventoryTransactions();
});

final pendingTasksProvider = FutureProvider.autoDispose<PendingTasks>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchPendingTasks();
});
