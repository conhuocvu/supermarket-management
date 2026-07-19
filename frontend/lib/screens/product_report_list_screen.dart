import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/product_report.dart';
import '../providers/product_reports_provider.dart';
import '../providers/shell_layout_provider.dart';

class ProductReportListScreen extends ConsumerStatefulWidget {
  const ProductReportListScreen({super.key});

  @override
  ConsumerState<ProductReportListScreen> createState() => _ProductReportListScreenState();
}

class _ProductReportListScreenState extends ConsumerState<ProductReportListScreen> {
  String _searchQuery = '';
  String _committedSearch = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedIssueType = 'All';
  String _selectedStatus = 'All';
  Timer? _debounce;

  final List<String> _issueTypeOptions = [
    'All',
    'LOW_STOCK',
    'OUT_OF_STOCK',
    'NEAR_EXPIRY',
  ];

  final List<String> _statusOptions = [
    'All',
    'PENDING',
    'RESOLVED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Product Reports',
        breadcrumbs: ['Inventory', 'Product Reports'],
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openReportDetailDialog(ProductReport report) {
    final theme = Theme.of(context);
    final dateStr = report.createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.tryParse(report.createdAt!) ?? DateTime.now())
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report #${report.reportNumber} Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Report Meta Header
                Row(
                  children: [
                    _buildStatusChip(report.status, theme),
                    const SizedBox(width: 12),
                    _buildIssueTypeBadge(report.issueType ?? report.reportType, theme),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('SKU: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          Text(report.barcode.isEmpty ? 'N/A' : report.barcode, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          Text('Category: ', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          Text(report.categoryName, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (report.quantity != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reported Quantity: ${report.quantity!.toStringAsFixed(report.quantity! == report.quantity!.toInt() ? 0 : 1)} ${report.unitName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REPORTED BY', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(report.reporterName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (report.stockInDetailNumber != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STOCK BATCH ID', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('#${report.stockInDetailNumber}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text('DESCRIPTION / NOTES', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    (report.description != null && report.description!.isNotEmpty) ? report.description! : 'No description provided.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),

                // Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (report.stockInDetailNumber != null) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Record Disposal'),
                        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/stock/expiring-products/disposal/${report.stockInDetailNumber}');
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterParams = (
      search: _committedSearch,
      issueType: _selectedIssueType,
      status: _selectedStatus,
    );

    final reportsAsync = ref.watch(productReportsProvider(filterParams));

    return Scaffold(
      body: reportsAsync.when(
        data: (reports) {
          final pendingCount = reports.where((r) => r.status.toUpperCase() == 'PENDING').length;
          final resolvedCount = reports.where((r) => r.status.toUpperCase() == 'RESOLVED').length;
          final criticalCount = reports.where((r) => r.issueType == 'OUT_OF_STOCK' || r.issueType == 'EXPIRED' || r.issueType == 'DAMAGED').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KPI Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    return GridView.count(
                      crossAxisCount: isMobile ? 1 : 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 3.0 : 1.6,
                      children: [
                        _buildStatCard(
                          theme: theme,
                          title: 'TOTAL REPORTS',
                          value: reports.length.toString().padLeft(2, '0'),
                          color: theme.colorScheme.onSurface,
                          subtitle: 'Logged in system',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'PENDING REVIEW',
                          value: pendingCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.secondary,
                          subtitle: 'Awaiting controller action',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'RESOLVED',
                          value: resolvedCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.primary,
                          subtitle: 'Successfully handled',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'CRITICAL ISSUES',
                          value: criticalCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.error,
                          subtitle: 'Stockout / Expired / Damaged',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Main Table Card
                Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Filter & Action Header
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search by product name, barcode, reporter...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _debounce?.cancel();
                                              setState(() {
                                                _searchController.clear();
                                                _searchQuery = '';
                                                _committedSearch = '';
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (val) {
                                    setState(() => _searchQuery = val);
                                    _debounce?.cancel();
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                      setState(() => _committedSearch = val);
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _buildFilterDropdown(
                              theme: theme,
                              label: 'Issue: ',
                              value: _selectedIssueType,
                              items: _issueTypeOptions,
                              onChanged: (val) => setState(() => _selectedIssueType = val),
                            ),
                            const SizedBox(width: 12),
                            _buildFilterDropdown(
                              theme: theme,
                              label: 'Status: ',
                              value: _selectedStatus,
                              items: _statusOptions,
                              onChanged: (val) => setState(() => _selectedStatus = val),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Reload reports',
                              onPressed: () => ref.invalidate(productReportsProvider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Data Table Content
                        if (reports.isEmpty)
                          _buildEmptyState(theme)
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                    ),
                                    columnSpacing: 24,
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 72,
                                    columns: const [
                                      DataColumn(label: Text('Report ID')),
                                      DataColumn(label: Text('Date & Time')),
                                      DataColumn(label: Text('Product')),
                                      DataColumn(label: Text('Issue Type')),
                                      DataColumn(label: Text('Quantity')),
                                      DataColumn(label: Text('Reported By')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: reports.map((report) {
                                      final dateStr = report.createdAt != null
                                          ? DateFormat('MMM dd, HH:mm').format(DateTime.tryParse(report.createdAt!) ?? DateTime.now())
                                          : 'N/A';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              '#${report.reportNumber}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(dateStr)),
                                          DataCell(
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 220),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    report.productName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    report.barcode.isEmpty ? report.categoryName : report.barcode,
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(_buildIssueTypeBadge(report.issueType ?? report.reportType, theme)),
                                          DataCell(
                                            Text(
                                              report.quantity != null
                                                  ? '${report.quantity!.toStringAsFixed(report.quantity! == report.quantity!.toInt() ? 0 : 1)} ${report.unitName}'
                                                  : '--',
                                            ),
                                          ),
                                          DataCell(Text(report.reporterName)),
                                          DataCell(_buildStatusChip(report.status, theme)),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined),
                                              tooltip: 'View report details',
                                              onPressed: () => _openReportDetailDialog(report),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading product reports...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => _buildErrorState(err, theme),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required ThemeData theme,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color bg;
    Color fg;
    final upper = status.toUpperCase();

    if (upper == 'RESOLVED' || upper == 'APPROVED') {
      bg = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
      fg = theme.colorScheme.primary;
    } else if (upper == 'REJECTED') {
      bg = theme.colorScheme.errorContainer.withValues(alpha: 0.3);
      fg = theme.colorScheme.error;
    } else {
      bg = theme.colorScheme.secondaryContainer.withValues(alpha: 0.4);
      fg = theme.colorScheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        upper,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildIssueTypeBadge(String issueType, ThemeData theme) {
    Color bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    Color fg = theme.colorScheme.onSurfaceVariant;
    IconData icon = Icons.info_outline;

    final upper = issueType.toUpperCase();
    if (upper.contains('EXPIRED')) {
      bg = theme.colorScheme.errorContainer.withValues(alpha: 0.5);
      fg = theme.colorScheme.error;
      icon = Icons.event_busy;
    } else if (upper.contains('LOW') || upper.contains('OUT_OF_STOCK')) {
      bg = theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
      fg = theme.colorScheme.onSecondaryContainer;
      icon = Icons.warning_amber_rounded;
    } else if (upper.contains('DAMAGE') || upper.contains('MISSING')) {
      bg = theme.colorScheme.errorContainer.withValues(alpha: 0.2);
      fg = theme.colorScheme.error;
      icon = Icons.broken_image_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            upper.replaceAll('_', ' '),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No product reports found.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Product report data cannot be loaded.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref.invalidate(productReportsProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
