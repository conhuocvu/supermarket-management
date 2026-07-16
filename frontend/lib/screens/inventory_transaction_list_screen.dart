import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_transaction.dart';
import '../models/pending_task.dart';
import '../providers/inventory_transaction_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class InventoryTransactionListScreen extends ConsumerStatefulWidget {
  const InventoryTransactionListScreen({super.key});

  @override
  ConsumerState<InventoryTransactionListScreen> createState() =>
      _InventoryTransactionListScreenState();
}

class _InventoryTransactionListScreenState
    extends ConsumerState<InventoryTransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // Default to Pending Tasks

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Inventory Transactions',
            actions: [],
            breadcrumbs: ['Inventory', 'Transactions'],
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 4,
            labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: theme.textTheme.titleMedium,
            tabs: const [
              Tab(text: 'Pending Tasks'),
              Tab(text: 'Transaction History'),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTasksTab(),
                  _buildTransactionHistoryTab(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksTab() {
    final asyncPendingTasks = ref.watch(pendingTasksProvider);

    return asyncPendingTasks.when(
      data: (pendingTasks) {
        if (pendingTasks.pendingStockIns.isEmpty &&
            pendingTasks.pendingStockOuts.isEmpty) {
          return EmptyView(
            icon: Icons.pending_actions,
            title: 'No Pending Tasks',
            description: 'Pending Stock-In and Stock-Out tasks will appear here.',
            actionLabel: 'Refresh',
            onActionPressed: () => ref.invalidate(pendingTasksProvider),
          );
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1000;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingTasksProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Stock-In Section
                  if (pendingTasks.pendingStockIns.isNotEmpty) ...[
                    _buildSectionHeader(
                      context: context,
                      icon: Icons.login_rounded,
                      title: 'Pending Stock-In',
                      count: pendingTasks.pendingStockIns.length,
                    ),
                    const SizedBox(height: 16),
                    _buildStockInTable(context, pendingTasks.pendingStockIns),
                    const SizedBox(height: 32),
                  ],

                  // Pending Stock-Out Section
                  if (pendingTasks.pendingStockOuts.isNotEmpty) ...[
                    _buildSectionHeader(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Pending Stock-Out',
                      count: pendingTasks.pendingStockOuts.length,
                    ),
                    const SizedBox(height: 16),
                    _buildStockOutTable(context, pendingTasks.pendingStockOuts),
                    const SizedBox(height: 32),
                  ],

                  // Bento Grid
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildActivityMapCard(context)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildWorkloadCard(context)),
                      ],
                    )
                  else ...[
                    _buildActivityMapCard(context),
                    const SizedBox(height: 24),
                    _buildWorkloadCard(context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        title: 'Failed to load pending tasks.',
        description: error.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(pendingTasksProvider),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStockInTable(BuildContext context, List<PendingStockIn> items) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width >= 1000
                ? MediaQuery.of(context).size.width - 256 - 96
                : MediaQuery.of(context).size.width - 96,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerLow,
            ),
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('REQUEST ID')),
              DataColumn(label: Text('REQUEST DATE')),
              DataColumn(label: Text('SUPPLIER')),
              DataColumn(label: Text('ITEMS'), numeric: true),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: items.map((item) {
              final isApproved = item.status?.toUpperCase() == 'APPROVED';
              
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#SI-${item.purchaseRequestNumber}',
                      style: const TextStyle(
                        fontFamily: 'Courier Prime',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(item.createdDate != null ? _formatDate(item.createdDate) : '-'),
                  ),
                  DataCell(
                    Text(
                      item.supplierName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.totalItems?.toStringAsFixed(0) ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(item.unitName ?? '-')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isApproved 
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          width: 1,
                          color: isApproved
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.colorScheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isApproved ? 'APPROVED' : 'PARTIALLY RECEIVED',
                        style: TextStyle(
                          color: isApproved 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FilledButton(
                        onPressed: () async {
                          final supplierQuery = item.supplierNumber != null ? '?supplierNumber=${item.supplierNumber}' : '';
                          final result = await context.push<bool>(
                            '/stock/transactions/record-stock-in/${item.purchaseRequestNumber}$supplierQuery',
                          );
                          if (result == true) {
                            ref.invalidate(pendingTasksProvider);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Record Stock-In'),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStockOutTable(BuildContext context, List<PendingStockOut> items) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width >= 1000
                ? MediaQuery.of(context).size.width - 256 - 96
                : MediaQuery.of(context).size.width - 96,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerLow,
            ),
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('REPORT ID')),
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('QTY'), numeric: true),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('LOCATION')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#SO-${item.reportNumber}',
                      style: const TextStyle(
                        fontFamily: 'Courier Prime',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.productName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      item.quantity?.toStringAsFixed(0) ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(item.unitName ?? '-')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(
                        item.location ?? 'A-12-04',
                        style: const TextStyle(
                          fontFamily: 'Courier Prime',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(item.createdAt != null ? _formatDate(item.createdAt) : '-'),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: FilledButton(
                        onPressed: () async {
                          final result = await context.push<bool>(
                            '/stock/transactions/record-stock-out/${item.reportNumber}',
                          );
                          if (result == true) {
                            ref.invalidate(pendingTasksProvider);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Record Stock-Out'),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityMapCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVITY MAP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(Icons.grid_view_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warehouse_rounded,
                      size: 32,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Warehouse Grid Heatmap',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WORKLOAD DISTRIBUTION',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem(context, theme.colorScheme.primary, 'Stock-In'),
                    const SizedBox(width: 12),
                    _buildLegendItem(context, theme.colorScheme.secondary, 'Stock-Out'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWorkloadBar(context, 'MON', 0.4, 0.2),
                  _buildWorkloadBar(context, 'TUE', 0.6, 0.8),
                  _buildWorkloadBar(context, 'WED', 0.8, 0.5),
                  _buildWorkloadBar(context, 'THU', 0.3, 0.9),
                  _buildWorkloadBar(context, 'FRI', 0.7, 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadBar(BuildContext context, String day, double inVal, double outVal) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 100 * inVal,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 100 * outVal,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryTab() {
    final asyncTransactions = ref.watch(inventoryTransactionsProvider);

    return asyncTransactions.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return EmptyView(
            icon: Icons.history,
            title: 'No Transactions',
            description: 'There are no inventory transactions yet.',
            actionLabel: 'Refresh',
            onActionPressed: () => ref.invalidate(inventoryTransactionsProvider),
          );
        }
        return Column(
          children: [
            Expanded(child: _buildTable(context, transactions)),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        title: 'Failed to load transactions.',
        description: error.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(inventoryTransactionsProvider),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Widget _buildTable(BuildContext context, List<InventoryTransaction> transactions) {
    final theme = Theme.of(context);


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width >= 1000
              ? MediaQuery.of(context).size.width - 256 - 96
              : MediaQuery.of(context).size.width - 96,
        ),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerLow,
            ),
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('TRANSACTION NO')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('PRODUCT')),
              DataColumn(label: Text('QTY'), numeric: true),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('REASON')),
            ],
            rows: transactions.map((tx) {
              final isStockIn = tx.type?.toUpperCase() == 'IN';
              
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#TX-${tx.transactionNumber}',
                      style: const TextStyle(
                        fontFamily: 'Courier Prime',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(tx.createdAt != null ? _formatDate(tx.createdAt) : '-'),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isStockIn ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isStockIn ? 'STOCK IN' : 'STOCK OUT',
                        style: TextStyle(
                          color: isStockIn ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(
                    tx.productName ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(
                    tx.quantity?.toStringAsFixed(0) ?? '0',
                    style: TextStyle(
                      color: isStockIn ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                  DataCell(Text(tx.unitName ?? '-')),
                  DataCell(Text(tx.reason ?? '-')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
