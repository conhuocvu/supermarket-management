import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/low_stock_product.dart';
import '../providers/low_stock_provider.dart';
import '../providers/purchase_request_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../providers/dashboard_provider.dart';

class LowStockProductListScreen extends ConsumerStatefulWidget {
  const LowStockProductListScreen({super.key});

  @override
  ConsumerState<LowStockProductListScreen> createState() => _LowStockProductListScreenState();
}

class _LowStockProductListScreenState extends ConsumerState<LowStockProductListScreen> {
  final Set<int> _selectedProductNumbers = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isCreatingRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Low Stock Management',
        breadcrumbs: ['Inventory', 'Low Stock'],
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculateEstimatedReorderCost(List<LowStockProduct> products) {
    return products.fold(0.0, (sum, p) => sum + (p.suggestedQuantity * p.importPrice));
  }

  Future<void> _createPurchaseRequest() async {
    if (_selectedProductNumbers.isEmpty) return;

    setState(() {
      _isCreatingRequest = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createPurchaseRequest(_selectedProductNumbers.toList());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${_selectedProductNumbers.length} products added to draft purchase request.'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Clear selection
        setState(() {
          _selectedProductNumbers.clear();
        });

        // Navigate to the purchase request draft form screen
        context.push('/stock/purchase-requests/create');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to initiate purchase request: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingRequest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowStockAsync = ref.watch(lowStockProductsProvider);
    final prAsync = ref.watch(purchaseRequestsProvider);

    return Scaffold(
      body: lowStockAsync.when(
        data: (products) {
          final pendingCount = prAsync.when(
            data: (list) => list.where((pr) => pr.status.toUpperCase() == 'PENDING').length,
            loading: () => 0,
            error: (err, stack) => 0,
          );

          final filteredProducts = products.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.productName.toLowerCase().contains(query) ||
                p.sku.toLowerCase().contains(query);
          }).toList();

          final criticalCount = products.where((p) => p.critical).length;
          final estCost = _calculateEstimatedReorderCost(products);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Stats Grid
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
                          title: 'CRITICAL ITEMS',
                          value: criticalCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.error,
                          progress: products.isEmpty ? 0.0 : criticalCount / products.length,
                          progressColor: theme.colorScheme.error,
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'PENDING REQUESTS',
                          value: pendingCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.secondary,
                          progress: pendingCount == 0 ? 0.0 : (pendingCount / 10.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.secondary,
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'EST. REORDER COST',
                          value: NumberFormat.compactSimpleCurrency(locale: 'en_US').format(estCost),
                          color: theme.colorScheme.primary,
                          progress: estCost == 0 ? 0.0 : (estCost / 5000.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.primary,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Search Bar and Quick Actions Area
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
                            hintText: 'Search items...',
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Data Table Container
                Card(
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
                              'Low Stock Tracking List',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Last updated: ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filteredProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No low-stock products found'
                                    : 'No matching products found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 320,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                ),
                                columns: const [
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Current Stock')),
                                  DataColumn(label: Text('Reorder Point')),
                                  DataColumn(label: Text('Suggestion')),
                                  DataColumn(label: Text('', textAlign: TextAlign.right)),
                                ],
                                rows: filteredProducts.map((p) {
                                  final isSelected = _selectedProductNumbers.contains(p.productNumber);
                                  return DataRow(
                                    selected: isSelected,
                                    onSelectChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedProductNumbers.add(p.productNumber);
                                        } else {
                                          _selectedProductNumbers.remove(p.productNumber);
                                        }
                                      });
                                    },
                                    cells: [
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              p.productName,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'SKU: ${p.sku}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${p.currentStock.toStringAsFixed(0)} ${p.unitName}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${p.reorderLevel.toStringAsFixed(0)} ${p.unitName}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: p.critical ? theme.colorScheme.error : null,
                                            fontWeight: p.critical ? FontWeight.bold : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          p.suggestion,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: p.critical ? theme.colorScheme.error : theme.colorScheme.primary,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: p.critical ? FontWeight.bold : null,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: isSelected
                                              ? FilledButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedProductNumbers.remove(p.productNumber);
                                                    });
                                                  },
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: const Text('Selected'),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: theme.colorScheme.primaryContainer,
                                                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                )
                                              : OutlinedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedProductNumbers.add(p.productNumber);
                                                    });
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  ),
                                                  child: const Text('Select Product'),
                                                ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                          border: Border(
                            top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Text(
                          'End of Low Stock Items - Total Count: ${filteredProducts.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Floating Actions Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Simulated Report Export
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Report exported as low_stock_report.txt successfully.'),
                            backgroundColor: theme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Export Report (.txt)'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Simulated Print List
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('List sent to printer successfully.'),
                            backgroundColor: theme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print List'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    if (_selectedProductNumbers.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _isCreatingRequest ? null : _createPurchaseRequest,
                        icon: _isCreatingRequest
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: Text('Create Purchase Request (${_selectedProductNumbers.length})'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            color: theme.colorScheme.errorContainer,
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
                    'Low-stock product data cannot be loaded.',
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
                        onPressed: () => ref.invalidate(lowStockProductsProvider),
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              color: progressColor,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
