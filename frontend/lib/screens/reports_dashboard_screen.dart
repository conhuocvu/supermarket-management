import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reports_provider.dart';
import '../models/reports_dashboard_data.dart';
import '../providers/shell_layout_provider.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  ConsumerState<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends ConsumerState<ReportsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Reports Dashboard',
            breadcrumbs: ['Manager', 'Reports'],
            subtitle: null, // ensure breadcrumbs display
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context, ReportsState state) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: state.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF40826D),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != state.dateRange) {
      ref.read(reportsProvider.notifier).updateDateRange(picked);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final df = DateFormat('MMM dd, yyyy');
    return '${df.format(range.start)} - ${df.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reportsProvider);

    return Column(
      children: [
        // ── Filter & Actions Header ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              // Left subheader description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial and Operational Overview for Store #402',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Date Range Picker & Export PDF buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _selectDateRange(context, state),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text(_formatDateRange(state.dateRange)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF40826D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => ref.read(reportsProvider.notifier).downloadPdf(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('DOWNLOAD PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Tab Bar Navigation ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF40826D),
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: const Color(0xFF40826D),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3.0,
              tabs: const [
                Tab(text: 'Statistics'),
                Tab(text: 'Revenue'),
                Tab(text: 'Inventory'),
                Tab(text: 'Waste'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Tab Contents ───────────────────────────────────────────
        Expanded(
          child: state.data.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF40826D))),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load dashboard.',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF40826D)),
                      onPressed: () => ref.read(reportsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) => TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(context, theme, data.statistics),
                _buildRevenueTab(context, theme, data.revenue),
                _buildInventoryTab(context, theme, data.inventory),
                _buildWasteTab(context, theme, data.waste),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 1. STATISTICS TAB ──────────────────────────────────────────
  Widget _buildStatisticsTab(BuildContext context, ThemeData theme, StatisticsSection stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: cols == 4 ? 1.7 : 2.5,
                children: [
                  _buildKpiCard(
                    context,
                    theme,
                    'GROSS SALES',
                    '\$${NumberFormat('#,##0.00').format(stats.grossSales)}',
                    stats.grossSalesTrend,
                    true,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'AVG BASKET',
                    '\$${stats.avgBasket.toStringAsFixed(2)}',
                    stats.avgBasketTrend,
                    true,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'STOCK TURN',
                    '${stats.stockTurn.toStringAsFixed(1)}x',
                    stats.stockTurnTrend,
                    false,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'FOOT TRAFFIC',
                    NumberFormat('#,##0').format(stats.footTraffic),
                    stats.footTrafficTrend,
                    true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main charts (Line Chart and Progress Bars side by side)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final chartWidth = isWide ? constraints.maxWidth * 0.65 : constraints.maxWidth;
              final catWidth = isWide ? constraints.maxWidth * 0.31 : constraints.maxWidth;

              final widgets = [
                // Daily Sales Velocity
                Container(
                  width: chartWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                            'SALES VELOCITY (DAILY)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Bricolage Grotesque',
                            ),
                          ),
                          Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 220,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: LineChartPainter(
                            points: stats.salesVelocity,
                            lineColor: const Color(0xFF40826D),
                            gradientStartColor: const Color(0xFF40826D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(stats.salesVelocity.first.label, style: theme.textTheme.bodySmall),
                          Text(stats.salesVelocity[stats.salesVelocity.length ~/ 2].label, style: theme.textTheme.bodySmall),
                          Text(stats.salesVelocity.last.label, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isWide) const SizedBox(height: 24),
                // Top Categories progress bar card
                Container(
                  width: catWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOP CATEGORIES',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Bricolage Grotesque',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...stats.topCategories.map((c) => _buildCategoryProgressRow(theme, c)),
                    ],
                  ),
                ),
              ];

              return isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widgets,
                    )
                  : Column(children: widgets);
            },
          ),
          const SizedBox(height: 24),

          // Anomalies Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                      'RECENT ANOMALIES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Bricolage Grotesque',
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                            ),
                          ),
                          child: const Text('ALL EVENTS'),
                        ),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black87,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                            ),
                          ),
                          child: const Text('HIGH PRIORITY'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 700),
                    child: DataTable(
                      headingRowHeight: 48,
                      columns: const [
                        DataColumn(label: Text('TIMESTAMP')),
                        DataColumn(label: Text('ENTITY')),
                        DataColumn(label: Text('EVENT TYPE')),
                        DataColumn(label: Text('VALUE')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: stats.recentAnomalies.map((anom) {
                        return DataRow(
                          cells: [
                            DataCell(Text(anom.timestamp)),
                            DataCell(Text(anom.entity, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: anom.eventType == 'OUT_OF_STOCK'
                                      ? const Color(0xFFDC2626).withOpacity(0.1)
                                      : const Color(0xFFF4A261).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  anom.eventType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: anom.eventType == 'OUT_OF_STOCK'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(anom.value)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.launch_rounded, size: 18),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Details for ${anom.entity}')),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'VIEW ALL LOGS',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF40826D)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Data refreshes every 15 mins',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. REVENUE TAB ─────────────────────────────────────────────
  Widget _buildRevenueTab(BuildContext context, ThemeData theme, RevenueSection rev) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildKpiCard(
                    context,
                    theme,
                    'NET SALES',
                    '\$${NumberFormat('#,##0.00').format(rev.netSales)}',
                    rev.netSalesTrend,
                    true,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'NET PROFIT',
                    '\$${NumberFormat('#,##0.00').format(rev.netProfit)}',
                    rev.netProfitTrend,
                    true,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'GROSS MARGIN',
                    '${rev.grossMargin.toStringAsFixed(1)}%',
                    rev.grossMarginTrend,
                    true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REVENUE TRENDS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bricolage Grotesque',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: LineChartPainter(
                      points: rev.revenueTrend,
                      lineColor: const Color(0xFF3B82F6),
                      gradientStartColor: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. INVENTORY TAB ───────────────────────────────────────────
  Widget _buildInventoryTab(BuildContext context, ThemeData theme, InventorySection inv) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 3 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildKpiCard(
                    context,
                    theme,
                    'TOTAL STOCK VALUE',
                    '\$${NumberFormat('#,##0.00').format(inv.totalStockValue)}',
                    inv.stockValueTrend,
                    true,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'LOW STOCK ALERTS',
                    inv.lowStockAlerts.toString(),
                    'Needs refill',
                    false,
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'TURNOVER RATE',
                    '${inv.stockTurnoverRate.toStringAsFixed(1)}x',
                    'Target: 5.0x',
                    true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVENTORY DISTRIBUTION BY CATEGORY',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bricolage Grotesque',
                  ),
                ),
                const SizedBox(height: 24),
                ...inv.inventoryDistribution.map((c) => _buildCategoryProgressRow(theme, c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. WASTE TAB ───────────────────────────────────────────────
  Widget _buildWasteTab(BuildContext context, ThemeData theme, WasteSection waste) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 600 ? 2 : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildKpiCard(
                    context,
                    theme,
                    'TOTAL WASTE VALUE',
                    '\$${NumberFormat('#,##0.00').format(waste.totalWasteValue)}',
                    waste.wasteValueTrend,
                    false, // negative is good for waste
                  ),
                  _buildKpiCard(
                    context,
                    theme,
                    'WASTE ITEMS COUNT',
                    waste.wasteItemsCount.toString(),
                    'Expired / Damaged',
                    false,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT WASTE EVENTS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Bricolage Grotesque',
                  ),
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: waste.recentWasteEvents.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final ev = waste.recentWasteEvents[index];
                    return ListTile(
                      leading: Icon(
                        ev.eventType == 'EXPIRED' ? Icons.timer_off_rounded : Icons.broken_image_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(ev.entity, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(ev.timestamp),
                      trailing: Text(
                        ev.value,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Card & Row Widgets ────────────────────────────────
  Widget _buildKpiCard(
    BuildContext context,
    ThemeData theme,
    String title,
    String value,
    String trend,
    bool isTrendPositiveGood,
  ) {
    final bool isPositive = trend.startsWith('+');
    final bool isNeutral = trend.contains('vs Target') || trend.contains('Need') || trend.contains('Expired');

    Color badgeColor = Colors.orange;

    if (!isNeutral) {
      final bool isGood = isTrendPositiveGood ? isPositive : !isPositive;
      badgeColor = isGood ? const Color(0xFF22C55E) : const Color(0xFFDC2626);
    } else {
      badgeColor = theme.colorScheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'Bricolage Grotesque',
              color: theme.colorScheme.onSurface,
            ),
          ),
          Row(
            children: [
              if (!isNeutral)
                Icon(
                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 14,
                  color: badgeColor,
                ),
              if (!isNeutral) const SizedBox(width: 4),
              Text(
                trend,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isNeutral ? theme.colorScheme.onSurfaceVariant : badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgressRow(ThemeData theme, CategoryPercentage c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c.categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${c.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.percentage / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF40826D)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM LINE CHART PAINTER ──────────────────────────────────
class LineChartPainter extends CustomPainter {
  final List<SalesVelocityPoint> points;
  final Color lineColor;
  final Color gradientStartColor;

  LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.gradientStartColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    double maxVal = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    double minVal = points.map((p) => p.amount).reduce((a, b) => a < b ? a : b);
    if (maxVal == minVal) {
      maxVal += 1.0;
    }
    maxVal = maxVal * 1.1;

    final double dx = width / (points.length - 1);

    final Path path = Path();
    final Path fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final double x = i * dx;
      final double y = height - ((points[i].amount / maxVal) * height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        final double prevX = (i - 1) * dx;
        final double prevY = height - ((points[i - 1].amount / maxVal) * height);
        final double controlX1 = prevX + (dx / 2);
        final double controlY1 = prevY;
        final double controlX2 = prevX + (dx / 2);
        final double controlY2 = y;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final double y = height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(width, y), paintGrid);
    }

    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gradientStartColor.withOpacity(0.3),
        gradientStartColor.withOpacity(0.0),
      ],
    );
    final paintFill = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    final paintDot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final paintDotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    int step = points.length > 15 ? points.length ~/ 5 : 1;
    for (int i = 0; i < points.length; i += step) {
      final double x = i * dx;
      final double y = height - ((points[i].amount / maxVal) * height);
      canvas.drawCircle(Offset(x, y), 5, paintDot);
      canvas.drawCircle(Offset(x, y), 5, paintDotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gradientStartColor != gradientStartColor;
  }
}
