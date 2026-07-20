import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';
import '../providers/shell_layout_provider.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(managerDashboardDataProvider);

    Future<void> handleRefresh() async {
      try {
        await ref.read(managerDashboardDataProvider.notifier).refreshDashboard();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard refreshed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Refresh failed: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }

    final actions = [
      IconButton(
        onPressed: handleRefresh,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Refresh',
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Good ${_getGreeting()}, Manager',
        subtitle: '${_formatDate(DateTime.now())} • Store Operating Normally',
        actions: actions,
      );
    });

    Widget buildBody() {
      return dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Statistics data unavailable.',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(managerDashboardDataProvider.notifier).loadDashboard(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _ManagerDashboardBody(
          data: data,
          onRefresh: handleRefresh,
        ),
      );
    }

    return buildBody();
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _ManagerDashboardBody extends StatelessWidget {
  final dynamic data;
  final Future<void> Function() onRefresh;

  const _ManagerDashboardBody({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        final padding = isWide ? 28.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KPI Cards ---
              _buildKpiRow(context, isWide),
              const SizedBox(height: 24),
              // --- Charts Row ---
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildWeeklyRevenueCard(context)),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: _buildInventoryDistributionCard(context)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildWeeklyRevenueCard(context),
                        const SizedBox(height: 20),
                        _buildInventoryDistributionCard(context),
                      ],
                    ),
              const SizedBox(height: 24),
              // --- Low Stock Alerts + Recent Activity Row ---
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildLowStockSection(context)),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: _buildRecentActivityCard(context)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildLowStockSection(context),
                        const SizedBox(height: 20),
                        _buildRecentActivityCard(context),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiRow(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final currencyFmt = _formatCurrency(data.revenueToday);

    final kpis = [
      _KpiData(
        label: 'REVENUE TODAY',
        value: currencyFmt,
        icon: Icons.account_balance_wallet_outlined,
        subLabel: '${data.totalRevenue > 0 ? '+${(data.revenueToday / data.totalRevenue * 100).toStringAsFixed(1)}%' : '0%'} of total',
        subColor: theme.colorScheme.primary,
      ),
      _KpiData(
        label: 'ACTIVE ORDERS',
        value: data.activeOrdersCount.toString(),
        icon: Icons.shopping_cart_checkout_rounded,
        subLabel: 'Today\'s transactions',
        subColor: theme.colorScheme.primary,
      ),
      _KpiData(
        label: 'ON-SHIFT STAFF',
        value: data.totalStaff.toString(),
        icon: Icons.people_alt_outlined,
        subLabel: 'Total staff members',
        subColor: theme.colorScheme.onSurfaceVariant,
      ),
      _KpiData(
        label: 'STOCK LEVEL',
        value: '${data.stockLevel.toStringAsFixed(0)}%',
        icon: Icons.inventory_2_outlined,
        subLabel: data.lowStockCount > 0 ? '${data.lowStockCount} Alerts pending' : 'No alerts',
        subColor: data.lowStockCount > 0 ? theme.colorScheme.secondary : theme.colorScheme.primary,
        valueColor: data.stockLevel < 80
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSurface,
      ),
    ];

    if (isWide) {
      return Row(
        children: kpis
            .map((kpi) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: kpi == kpis.last ? 0 : 16),
                    child: _KpiCard(kpi: kpi),
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(kpi: kpis[0])),
            const SizedBox(width: 12),
            Expanded(child: _KpiCard(kpi: kpis[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _KpiCard(kpi: kpis[2])),
            const SizedBox(width: 12),
            Expanded(child: _KpiCard(kpi: kpis[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyRevenueCard(BuildContext context) {
    final theme = Theme.of(context);
    final weekly = data.weeklyRevenue as List;
    final maxAmt = weekly.isEmpty
        ? 1.0
        : weekly.map((e) => e.amount as double).reduce((a, b) => a > b ? a : b).toDouble();
    final totalWeekly = weekly.fold<double>(0, (sum, e) => sum + (e.amount as double));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY REVENUE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              Text(
                '${_formatCurrency(totalWeekly)} Total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekly.map<Widget>((e) {
                final pct = maxAmt > 0 ? (e.amount as double) / maxAmt : 0.0;
                final isToday = weekly.indexOf(e) == weekly.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: 110 * pct,
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.25),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.day as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryDistributionCard(BuildContext context) {
    final theme = Theme.of(context);
    final dist = (data.inventoryDistribution as List).take(5).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVENTORY DISTRIBUTION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          ...dist.map((item) {
            final pct = (item.percentage as double).clamp(0.0, 100.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.categoryName as String,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLowStockSection(BuildContext context) {
    final theme = Theme.of(context);
    final lowStockCount = data.lowStockCount as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low Stock Alerts', style: theme.textTheme.headlineSmall),
            TextButton(
              onPressed: () {},
              child: const Text('View All Alerts'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (lowStockCount == 0)
          _Card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All stock levels are healthy', style: theme.textTheme.labelLarge),
                      Text(
                        'No items below reorder level.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lowStockCount > 6 ? 6 : lowStockCount,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final level = index == 0 ? 'URGENT' : index == 1 ? 'CRITICAL' : 'LOW';
                final badgeColor = index == 0
                    ? theme.colorScheme.error
                    : index == 1
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outline;
                final unitsLeft = (lowStockCount - index * 3).clamp(1, 20);
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          level,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Product ${index + 1}',
                        style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$unitsLeft units left',
                        style: theme.textTheme.labelSmall?.copyWith(color: badgeColor),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    final theme = Theme.of(context);
    final activities = data.recentActivities as List;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: theme.textTheme.headlineSmall),
              TextButton(onPressed: () {}, child: const Text('History')),
            ],
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No recent activity.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...activities.map((activity) => _buildActivityItem(context, activity)),
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: const Text('View All Activity'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, dynamic activity) {
    final theme = Theme.of(context);
    final action = activity.action as String;

    IconData icon;
    Color iconBg;
    Color iconColor;

    if (action.contains('Delivery') || action.contains('Supplier')) {
      icon = Icons.local_shipping_rounded;
      iconBg = theme.colorScheme.primary.withValues(alpha: 0.12);
      iconColor = theme.colorScheme.primary;
    } else if (action.contains('Promotion')) {
      icon = Icons.campaign_rounded;
      iconBg = theme.colorScheme.secondary.withValues(alpha: 0.12);
      iconColor = theme.colorScheme.secondary;
    } else if (action.contains('Staff') || action.contains('Onboard')) {
      icon = Icons.person_add_alt_1_rounded;
      iconBg = theme.colorScheme.primary.withValues(alpha: 0.12);
      iconColor = theme.colorScheme.primary;
    } else {
      icon = Icons.warning_amber_rounded;
      iconBg = theme.colorScheme.error.withValues(alpha: 0.12);
      iconColor = theme.colorScheme.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action as String,
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.item as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 11, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(
                      _formatTimeAgo(activity.time as DateTime),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final String subLabel;
  final Color subColor;
  final Color? valueColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.subLabel,
    required this.subColor,
    this.valueColor,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kpi.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
              Icon(kpi.icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kpi.value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kpi.valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.trending_up, size: 13, color: kpi.subColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  kpi.subLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: kpi.subColor,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
