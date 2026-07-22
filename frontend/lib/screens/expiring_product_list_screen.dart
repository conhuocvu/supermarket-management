import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/expiring_product.dart';
import '../providers/expiring_products_provider.dart';
import '../providers/clearance_proposal_provider.dart';
import '../providers/shell_layout_provider.dart';

class ExpiringProductListScreen extends ConsumerStatefulWidget {
  const ExpiringProductListScreen({super.key});

  @override
  ConsumerState<ExpiringProductListScreen> createState() => _ExpiringProductListScreenState();
}

class _ExpiringProductListScreenState extends ConsumerState<ExpiringProductListScreen> {
  String _statusFilter = 'All'; // All, Expired, Critical, Warning

  // Local lists to mock client-side updates (disposals/discounts)
  final Set<int> _dismissedDetailNumbers = {};
  final int _localProposedDiscountsCount = 8;
  final int _localDisposalsCount = 3;
  int _activeTabIndex = 0; // 0: Watchlist, 1: Submitted Proposals

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Near-Expiry Management',
        breadcrumbs: ['Inventory', 'Expiring Products'],
      );
    });
  }

  String _formatQuantity(double qty, String productName) {
    final nameLower = productName.toLowerCase();
    String unit = 'Pcs';
    if (nameLower.contains('milk') || nameLower.contains('beverage') || nameLower.contains('juice') || nameLower.contains('water')) {
      unit = 'Liters';
    } else if (nameLower.contains('salmon') || nameLower.contains('meat') || nameLower.contains('tomato')) {
      unit = 'Grams';
    }
    
    if (qty == qty.toInt()) {
      return '${qty.toInt()} $unit';
    }
    return '${qty.toStringAsFixed(1)} $unit';
  }

  void _openDiscountProposalDialog(ExpiringProduct product) {
    context.go('/stock/expiring-products/clearance-proposal/${product.stockInDetailNumber}');
  }

  void _openDisposalDialog(ExpiringProduct product) {
    context.go('/stock/expiring-products/disposal/${product.stockInDetailNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterParams = (search: '', status: _statusFilter);
    final expiringAsync = ref.watch(expiringProductsProvider(filterParams));

    return Scaffold(
      body: expiringAsync.when(
        data: (products) {
          // Exclude locally dismissed items
          final filteredProducts = products
              .where((p) => !_dismissedDetailNumbers.contains(p.stockInDetailNumber))
              .toList();

          final criticalCount = filteredProducts.where((p) => p.daysRemaining >= 0 && p.daysRemaining <= 7).length;
          final totalNearExpiryCount = filteredProducts.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Summary Stats Cards (TOTAL NEAR EXPIRY, PROPOSED DISCOUNTS, DISPOSALS TODAY)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return GridView.count(
                      crossAxisCount: isMobile ? 1 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 3.0 : 1.6,
                      children: [
                        _buildStatCard(
                          theme: theme,
                          title: 'TOTAL NEAR EXPIRY',
                          value: totalNearExpiryCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.onSurface,
                          progress: totalNearExpiryCount == 0 ? 0.0 : (totalNearExpiryCount / 30.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.primary,
                          subtitle: 'Critical (< 7 days): $criticalCount',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'PROPOSED DISCOUNTS',
                          value: _localProposedDiscountsCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.primary,
                          progress: (_localProposedDiscountsCount / 20.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.primary,
                          subtitle: 'Potential Loss Mitigation: \$1,240',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'DISPOSALS TODAY',
                          value: _localDisposalsCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.error,
                          progress: (_localDisposalsCount / 10.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.error,
                          subtitle: 'Log ID: 9942-A',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Segmented Tab Bar (Watchlist vs Submitted Proposals)
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('Near-Expiry Watchlist'),
                      icon: Icon(Icons.warning_amber_rounded),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('Submitted Proposals'),
                      icon: Icon(Icons.local_offer_outlined),
                    ),
                  ],
                  selected: {_activeTabIndex},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _activeTabIndex = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                if (_activeTabIndex == 0)
                  _buildWatchlistSection(theme, filteredProducts)
                else
                  _buildSubmittedProposalsSection(theme),
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
                  'Loading expiring products...',
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

  Widget _buildWatchlistSection(ThemeData theme, List<ExpiringProduct> filteredProducts) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Title on left and Filter + Export on right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Expiry Watchlist',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildFilterDropdown(theme),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Expiring products watchlist exported successfully.'),
                            backgroundColor: theme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (filteredProducts.isEmpty)
            _buildEmptyState(theme)
          else
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 320 > 800
                        ? MediaQuery.of(context).size.width - 320
                        : 800,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                    ),
                    columnSpacing: 24,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Days Remaining', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Batch ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredProducts.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              product.productName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          DataCell(
                            _buildDaysRemainingBadge(product, theme),
                          ),
                          DataCell(
                            Text(
                              _formatQuantity(product.quantity, product.productName),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              product.batchNumber,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                FilledButton(
                                  onPressed: () => _openDiscountProposalDialog(product),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Propose Discount', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _openDisposalDialog(product),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.onSurface,
                                    side: BorderSide(color: theme.colorScheme.outline),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Record Disposal', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaysRemainingBadge(ExpiringProduct product, ThemeData theme) {
    final days = product.daysRemaining;
    Color bg;
    Color fg;
    Border? border;

    if (days < 0) {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'EXPIRED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: fg,
          ),
        ),
      );
    } else if (days <= 2) {
      bg = Colors.black;
      fg = Colors.white;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${days.toString().padLeft(2, '0')} DAYS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: fg,
          ),
        ),
      );
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      fg = theme.colorScheme.onSurface;
      border = Border.all(color: theme.colorScheme.outlineVariant);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Text(
          '${days.toString().padLeft(2, '0')} DAYS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: fg,
          ),
        ),
      );
    }
  }

  Widget _buildFilterDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          icon: const Icon(Icons.filter_list, size: 18),
          isDense: true,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Expiry')),
            DropdownMenuItem(value: 'Expired', child: Text('Expired')),
            DropdownMenuItem(value: 'Critical', child: Text('Critical (<=7d)')),
            DropdownMenuItem(value: 'Warning', child: Text('Warning')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required Color color,
    required double progress,
    required Color progressColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              color: progressColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No expiring products found',
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
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Expiring product data cannot be loaded.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(expiringProductsProvider((search: '', status: _statusFilter))),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedProposalsSection(ThemeData theme) {
    final proposalsAsync = ref.watch(submittedClearanceProposalsProvider);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted Clearance Proposals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.invalidate(submittedClearanceProposalsProvider),
                  tooltip: 'Refresh Proposals',
                ),
              ],
            ),
          ),
          proposalsAsync.when(
            data: (proposals) {
              if (proposals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'No clearance proposals submitted yet.',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 320 > 800
                          ? MediaQuery.of(context).size.width - 320
                          : 800,
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                      ),
                      columnSpacing: 24,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('Proposal Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('End Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: proposals.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                p.promotionName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '-${p.discountValue.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(_buildProposalStatusBadge(p.status, theme)),
                            DataCell(Text(p.startDate ?? '--')),
                            DataCell(Text(p.endDate ?? '--')),
                            DataCell(
                              Text(
                                (p.description != null && p.description!.isNotEmpty)
                                    ? p.description!
                                    : 'N/A',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Failed to load submitted proposals: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalStatusBadge(String status, ThemeData theme) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status.toUpperCase()) {
      case 'PENDING':
        bg = Colors.amber.withValues(alpha: 0.2);
        fg = Colors.amber.shade900;
        label = 'PENDING APPROVAL';
        break;
      case 'ACTIVE':
      case 'APPROVED':
        bg = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
        fg = theme.colorScheme.primary;
        label = 'APPROVED';
        break;
      case 'EXPIRED':
      case 'INACTIVE':
      case 'REJECTED':
        bg = theme.colorScheme.errorContainer.withValues(alpha: 0.3);
        fg = theme.colorScheme.error;
        label = status.toUpperCase();
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
