import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/statistic_card.dart';

/// Sales Associate dashboard, backed by the real inventory and product-report
/// APIs. Mirrors the Inventory Dashboard structure: KPI cards, a warning
/// banner, recent reports, and quick actions.
class SalesDashboardScreen extends ConsumerStatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  ConsumerState<SalesDashboardScreen> createState() =>
      _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends ConsumerState<SalesDashboardScreen> {
  late Future<(List<InventoryProduct>, List<Map<String, dynamic>>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<InventoryProduct>, List<Map<String, dynamic>>)> _load() async {
    final api = ApiService();
    final results = await Future.wait([
      api.fetchInventoryProducts(size: 100),
      api.fetchMyProductReports(),
    ]);
    final products =
        ((results[0] as Map<String, dynamic>)['items']
                as List<InventoryProduct>)
            .where((p) => p.status == 'ACTIVE')
            .toList();
    final reports = results[1] as List<Map<String, dynamic>>;
    return (products, reports);
  }

  void _reload() => setState(() => _future = _load());

  bool _isExpired(InventoryProduct p) {
    if (p.expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(
      p.expiryDate!.year,
      p.expiryDate!.month,
      p.expiryDate!.day,
    ).isBefore(today);
  }

  String? _problemStatus(InventoryProduct p) {
    if (_isExpired(p)) return 'Expired';
    if (p.stock <= 0) return 'Out of Stock';
    if (p.stock <= p.reorderLevel) return 'Low Stock';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final fullName =
        authState.profile?.fullName ??
        authState.user?.email ??
        'Sales Associate';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: 'Sales Associate Dashboard',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _reload,
              ),
            ],
            breadcrumbs: ['Sales', 'Dashboard'],
          );
    });

    return FutureBuilder<(List<InventoryProduct>, List<Map<String, dynamic>>)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load dashboard data.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().replaceAll('Exception: ', ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final (products, reports) = snapshot.data!;

        final outOfStock = products
            .where((p) => _problemStatus(p) == 'Out of Stock')
            .length;
        final lowStock = products
            .where((p) => _problemStatus(p) == 'Low Stock')
            .length;
        final expired = products
            .where((p) => _problemStatus(p) == 'Expired')
            .length;
        final problemTotal = outOfStock + lowStock + expired;

        final myIssues = reports
            .where((r) => r['reportType'] == 'INVENTORY_ISSUE')
            .toList();
        final mySuggestions = reports
            .where((r) => r['reportType'] == 'UPDATE_SUGGESTION')
            .toList();
        final pendingCount = reports
            .where((r) => r['status'] == 'PENDING')
            .length;
        final recentReports = reports.take(6).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final sidePadding = isWide ? 24.0 : 16.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: sidePadding,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      'Welcome back, $fullName',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KPI Grid
                    _buildKpiGrid(
                      context,
                      totalProducts: products.length,
                      outOfStock: outOfStock,
                      lowStock: lowStock,
                      expired: expired,
                      pendingReports: pendingCount,
                    ),
                    const SizedBox(height: 24),

                    // Two column layout
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRecentReportsSection(
                                  context,
                                  recentReports,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    if (problemTotal > 0) ...[
                                      _buildWarningBanner(
                                        context,
                                        outOfStock,
                                        lowStock,
                                        expired,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    _buildMyActivitySnapshot(
                                      context,
                                      myIssues.length,
                                      mySuggestions.length,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildQuickActions(context),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              if (problemTotal > 0) ...[
                                _buildWarningBanner(
                                  context,
                                  outOfStock,
                                  lowStock,
                                  expired,
                                ),
                                const SizedBox(height: 24),
                              ],
                              _buildMyActivitySnapshot(
                                context,
                                myIssues.length,
                                mySuggestions.length,
                              ),
                              const SizedBox(height: 24),
                              _buildRecentReportsSection(
                                context,
                                recentReports,
                              ),
                              const SizedBox(height: 24),
                              _buildQuickActions(context),
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

  Widget _buildKpiGrid(
    BuildContext context, {
    required int totalProducts,
    required int outOfStock,
    required int lowStock,
    required int expired,
    required int pendingReports,
  }) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    final cards = [
      StatisticCard(
        title: 'Total Products',
        value: numberFormat.format(totalProducts),
        progressColor: theme.colorScheme.primary,
        progressPercent: 1.0,
      ),
      StatisticCard(
        title: 'Out of Stock',
        value: outOfStock.toString(),
        valueColor: theme.colorScheme.error,
        progressColor: theme.colorScheme.error,
        progressPercent: totalProducts > 0 ? (outOfStock / totalProducts) : 0.0,
      ),
      StatisticCard(
        title: 'Low Stock',
        value: lowStock.toString(),
        valueColor: theme.colorScheme.secondary,
        progressColor: theme.colorScheme.secondary,
        progressPercent: totalProducts > 0 ? (lowStock / totalProducts) : 0.0,
      ),
      StatisticCard(
        title: 'Expired',
        value: expired.toString(),
        valueColor: Colors.deepOrange,
        progressColor: Colors.deepOrange,
        progressPercent: totalProducts > 0 ? (expired / totalProducts) : 0.0,
      ),
      StatisticCard(
        title: 'My Pending Reports',
        value: pendingReports.toString(),
        valueColor: theme.colorScheme.primary,
        progressColor: theme.colorScheme.primaryContainer,
        progressPercent: 0.4,
      ),
    ];

    return LayoutBuilder(
      builder: (context, gridConstraints) {
        int columns = 1;
        if (gridConstraints.maxWidth >= 1100) {
          columns = 5;
        } else if (gridConstraints.maxWidth >= 900) {
          columns = 3;
        } else if (gridConstraints.maxWidth >= 600) {
          columns = 2;
        }

        final rows = <Widget>[];
        for (var i = 0; i < cards.length; i += columns) {
          final rowCards = cards.sublist(
            i,
            (i + columns).clamp(0, cards.length),
          );
          rows.add(
            Row(
              children: [
                for (var j = 0; j < rowCards.length; j++) ...[
                  if (j > 0) const SizedBox(width: 16),
                  Expanded(child: rowCards[j]),
                ],
                // Pad the last row so the cards keep their width
                for (var j = rowCards.length; j < columns; j++) ...[
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          );
          if (i + columns < cards.length) {
            rows.add(const SizedBox(height: 16));
          }
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildWarningBanner(
    BuildContext context,
    int outOfStock,
    int lowStock,
    int expired,
  ) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (outOfStock > 0) '$outOfStock out of stock',
      if (lowStock > 0) '$lowStock low stock',
      if (expired > 0) '$expired expired',
    ];

    return Container(
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
            'SHELF ALERT',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Products need attention: ${parts.join(', ')}',
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
              onPressed: () => context.go('/sales/reports'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: const Text('View Report Status'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyActivitySnapshot(
    BuildContext context,
    int issueCount,
    int suggestionCount,
  ) {
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
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Submissions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        issueCount.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        'Issue Reports',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        suggestionCount.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Suggestions',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/sales/reports'),
                child: const Text('View Report Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsSection(
    BuildContext context,
    List<Map<String, dynamic>> reports,
  ) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBFC9C3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('My Recent Reports',
                      style: isMobile
                          ? theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : theme.textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/sales/reports'),
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 24),
            if (reports.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No reports submitted yet. Report an issue or suggest an update from the product list.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (isMobile)
              // Mobile: compact rows instead of a table
              Column(
                children: [
                  for (final r in reports) _buildMobileReportRow(context, r),
                ],
              )
            else
              LayoutBuilder(
                builder: (context, tableConstraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Fill the card on wide screens; scroll on narrow ones
                        minWidth: tableConstraints.maxWidth < 500
                            ? 500
                            : tableConstraints.maxWidth,
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                        ),
                        children: [
                          TableRow(
                            children: [
                              _headerCell(theme, 'Type'),
                              _headerCell(theme, 'Product'),
                              _headerCell(theme, 'Status'),
                              _headerCell(theme, 'Time'),
                            ],
                          ),
                          ...reports.map((r) {
                            final isSuggestion =
                                r['reportType'] == 'UPDATE_SUGGESTION';
                            final status = (r['status'] ?? 'PENDING')
                                .toString();
                            final statusColor = _statusColor(status, theme);
                            final createdAt = DateTime.tryParse(
                              (r['createdAt'] ?? '').toString(),
                            );

                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSuggestion
                                            ? Icons.edit_note
                                            : Icons.report_problem,
                                        color: isSuggestion
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isSuggestion ? 'Suggestion' : 'Issue',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Text(
                                    '${r['productName'] ?? '-'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _titleCase(status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Text(
                                    createdAt != null
                                        ? _formatActivityTime(createdAt)
                                        : '-',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.8),
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Mobile row for a recent report — icon, product, status chip.
  Widget _buildMobileReportRow(BuildContext context, Map<String, dynamic> r) {
    final theme = Theme.of(context);
    final isSuggestion = r['reportType'] == 'UPDATE_SUGGESTION';
    final status = (r['status'] ?? 'PENDING').toString();
    final statusColor = _statusColor(status, theme);
    final createdAt = DateTime.tryParse((r['createdAt'] ?? '').toString());

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push(isSuggestion
          ? '/sales/reports/suggestions/${r['reportNumber']}'
          : '/sales/problems/${r['reportNumber']}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Icon(
              isSuggestion ? Icons.edit_note : Icons.report_problem,
              color: isSuggestion
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r['productName'] ?? '-'}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    createdAt != null ? _formatActivityTime(createdAt) : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _titleCase(status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      (
        Icons.list_alt,
        'Product List',
        theme.colorScheme.primary,
        () => context.go('/sales/products'),
      ),
      (
        Icons.report_problem,
        'Report Issue',
        theme.colorScheme.error,
        () => context.push('/sales/report-issue'),
      ),
      (
        Icons.edit_note,
        'Suggest Update',
        theme.colorScheme.primary,
        () => context.push('/sales/suggest-update'),
      ),
    ];

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
              children: [
                Icon(
                  Icons.bolt_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: actions.map((a) {
                final (icon, label, color, onTap) = a;
                return BentoCard(
                  onTap: onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

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

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'PENDING':
        return theme.colorScheme.secondary;
      case 'APPROVED':
      case 'RESOLVED':
        return theme.colorScheme.primary;
      case 'REJECTED':
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
