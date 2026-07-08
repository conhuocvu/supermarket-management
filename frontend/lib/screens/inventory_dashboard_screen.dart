import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/statistic_card.dart';
import 'package:intl/intl.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardDataProvider);

    // Refresh action trigger
    Future<void> handleRefresh() async {
      try {
        await ref.read(dashboardDataProvider.notifier).refreshDashboard();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data refreshed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refresh failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Inventory Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: handleRefresh,
          ),
        ],
      );
    });

    return dashboardState.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load dashboard data.',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.read(dashboardDataProvider.notifier).loadDashboard(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data.totalProducts == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No dashboard data available.',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Inventory data is empty or unavailable.'),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(dashboardDataProvider.notifier).loadDashboard(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                    ),
                  ],
                ),
              ),
            );
          }

          final numberFormat = NumberFormat('#,###');

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final sidePadding = isWide ? 24.0 : 16.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Grid
                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          int columns = 1;
                          if (gridConstraints.maxWidth >= 900) {
                            columns = 4;
                          } else if (gridConstraints.maxWidth >= 600) {
                            columns = 2;
                          }

                          if (columns == 4) {
                            return Row(
                              children: [
                                Expanded(
                                  child: StatisticCard(
                                    title: 'Total Products',
                                    value: numberFormat.format(data.totalProducts),
                                    progressColor: theme.colorScheme.primary,
                                    progressPercent: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatisticCard(
                                    title: 'Low Stock',
                                    value: data.lowStockCount.toString(),
                                    valueColor: theme.colorScheme.error,
                                    progressColor: theme.colorScheme.error,
                                    progressPercent: data.totalProducts > 0 
                                        ? (data.lowStockCount / data.totalProducts) 
                                        : 0.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatisticCard(
                                    title: 'Near Expiry',
                                    value: data.nearExpiryCount.toString(),
                                    valueColor: theme.colorScheme.secondary,
                                    progressColor: theme.colorScheme.secondary,
                                    progressPercent: 0.1, // Custom ratio for representation
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatisticCard(
                                    title: 'Pending Requests',
                                    value: data.pendingRequestsCount.toString(),
                                    valueColor: theme.colorScheme.primary,
                                    progressColor: theme.colorScheme.primaryContainer,
                                    progressPercent: 0.4, // Custom ratio for representation
                                  ),
                                ),
                              ],
                            );
                          } else if (columns == 2) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatisticCard(
                                        title: 'Total Products',
                                        value: numberFormat.format(data.totalProducts),
                                        progressColor: theme.colorScheme.primary,
                                        progressPercent: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: StatisticCard(
                                        title: 'Low Stock',
                                        value: data.lowStockCount.toString(),
                                        valueColor: theme.colorScheme.error,
                                        progressColor: theme.colorScheme.error,
                                        progressPercent: data.totalProducts > 0 
                                            ? (data.lowStockCount / data.totalProducts) 
                                            : 0.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatisticCard(
                                        title: 'Near Expiry',
                                        value: data.nearExpiryCount.toString(),
                                        valueColor: theme.colorScheme.secondary,
                                        progressColor: theme.colorScheme.secondary,
                                        progressPercent: 0.1,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: StatisticCard(
                                        title: 'Pending Requests',
                                        value: data.pendingRequestsCount.toString(),
                                        valueColor: theme.colorScheme.primary,
                                        progressColor: theme.colorScheme.primaryContainer,
                                        progressPercent: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                StatisticCard(
                                  title: 'Total Products',
                                  value: numberFormat.format(data.totalProducts),
                                  progressColor: theme.colorScheme.primary,
                                  progressPercent: 1.0,
                                ),
                                const SizedBox(height: 16),
                                StatisticCard(
                                  title: 'Low Stock',
                                  value: data.lowStockCount.toString(),
                                  valueColor: theme.colorScheme.error,
                                  progressColor: theme.colorScheme.error,
                                  progressPercent: data.totalProducts > 0 
                                      ? (data.lowStockCount / data.totalProducts) 
                                      : 0.0,
                                ),
                                const SizedBox(height: 16),
                                StatisticCard(
                                  title: 'Near Expiry',
                                  value: data.nearExpiryCount.toString(),
                                  valueColor: theme.colorScheme.secondary,
                                  progressColor: theme.colorScheme.secondary,
                                  progressPercent: 0.1,
                                ),
                                const SizedBox(height: 16),
                                StatisticCard(
                                  title: 'Pending Requests',
                                  value: data.pendingRequestsCount.toString(),
                                  valueColor: theme.colorScheme.primary,
                                  progressColor: theme.colorScheme.primaryContainer,
                                  progressPercent: 0.4,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Two Column Layout
                      isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildRecentActivitiesSection(context, data.recentActivities),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: _buildAlertsAndSnapshotSection(context, data.lowStockCount, data.capacityUsed, data.updatedAt),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildAlertsAndSnapshotSection(context, data.lowStockCount, data.capacityUsed, data.updatedAt),
                                const SizedBox(height: 24),
                                _buildRecentActivitiesSection(context, data.recentActivities),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }

  // Activity list builder
  Widget _buildRecentActivitiesSection(BuildContext context, List<dynamic> activities) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBFC9C3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Inventory Activities',
                  style: theme.textTheme.headlineSmall,
                ),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to transaction list in the future
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Activity', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Product', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Quantity', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text('Time', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    ...activities.map((activity) {
                      final isStockIn = activity.action == 'Stock-in';
                      final timeString = _formatActivityTime(activity.time);

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              children: [
                                Icon(
                                  isStockIn ? Icons.add_circle : Icons.remove_circle,
                                  color: isStockIn ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  activity.action,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(activity.item),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(activity.quantity),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              timeString,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Alerts and snapshot panel builder
  Widget _buildAlertsAndSnapshotSection(BuildContext context, int lowStockCount, double capacityUsed, DateTime updatedAt) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        if (lowStockCount > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.error, width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'SYSTEM WARNING',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$lowStockCount products are running low in stock',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirecting to purchase request creation...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    child: const Text('Order Now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Capacity snapshot
        Card(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFBFC9C3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'General Status',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (capacityUsed / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity Used',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${capacityUsed.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Updated ${_formatTimeAgo(updatedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helpers for time formatting
  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (activityDate == today) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (activityDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
