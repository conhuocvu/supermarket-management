import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_product_detail.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate product detail, backed by the real inventory API.
/// Rendered inside the AppScaffold shell so the sidebar stays visible.
class SalesProductDetailScreen extends ConsumerStatefulWidget {
  final int productNumber;

  const SalesProductDetailScreen({super.key, required this.productNumber});

  @override
  ConsumerState<SalesProductDetailScreen> createState() =>
      _SalesProductDetailScreenState();
}

class _SalesProductDetailScreenState
    extends ConsumerState<SalesProductDetailScreen> {
  late Future<InventoryProductDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ApiService().fetchProductDetails(widget.productNumber);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Product Detail',
            breadcrumbs: ['Sales', 'Products', 'Detail'],
          );
    });
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go('/sales/products');

  String _stockStatus(InventoryProductDetail p) {
    if (p.stock <= 0) return 'Out of Stock';
    if (p.stock <= p.reorderLevel) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return FutureBuilder<InventoryProductDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load product.\n${snapshot.error ?? ''}',
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() {
                      _detailFuture =
                          ApiService().fetchProductDetails(widget.productNumber);
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;
          final statusColor = _statusColor(_stockStatus(product), theme);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Inline header with back button (same pattern as stock detail)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      onPressed: _goBack,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        product.productName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildOverviewCard(context, product, statusColor),
                                const SizedBox(height: 16),
                                _buildStatisticsCard(context, product),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildSupplierCard(context, product),
                                const SizedBox(height: 16),
                                _buildHistoryCard(context, product),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildOverviewCard(context, product, statusColor),
                          const SizedBox(height: 16),
                          _buildStatisticsCard(context, product),
                          const SizedBox(height: 16),
                          _buildSupplierCard(context, product),
                          const SizedBox(height: 16),
                          _buildHistoryCard(context, product),
                        ],
                      ),
                const SizedBox(height: 24),
                _buildBottomButtons(context, product),
                const SizedBox(height: 48),
              ],
            ),
          );
        });
  }

  Widget _buildOverviewCard(BuildContext context,
      InventoryProductDetail product, Color statusColor) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 40,
        color: theme.colorScheme.primary,
      ),
    );

    return BentoCard(
      child: Row(
        children: [
          product.imageUrl.isEmpty
              ? placeholder
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.barcode,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  product.productName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  product.categoryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _stockStatus(product),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${product.stock.toStringAsFixed(0)} ${product.unitName} left',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(
      BuildContext context, InventoryProductDetail product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Metrics',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Selling Price',
                  '${product.sellingPrice.toStringAsFixed(0)} đ', theme),
              if (product.importPrice != null)
                _buildMetricItem('Import Price',
                    '${product.importPrice!.toStringAsFixed(0)} đ', theme),
              _buildMetricItem('Reorder Level',
                  '${product.reorderLevel.toStringAsFixed(0)} ${product.unitName}',
                  theme),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              product.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildSupplierCard(
      BuildContext context, InventoryProductDetail product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supply Specifications',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Supplier', product.supplierName, theme),
          const Divider(height: 12),
          _buildSpecRow('Barcode', product.barcode, theme),
          if (product.minimumOrderQuantity != null) ...[
            const Divider(height: 12),
            _buildSpecRow('Min Order Qty',
                product.minimumOrderQuantity!.toStringAsFixed(0), theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
      BuildContext context, InventoryProductDetail product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock History',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (product.stockHistory.isEmpty)
            Text(
              'No stock history yet.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: product.stockHistory.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final h = product.stockHistory[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.history,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${h.date} - ${h.action} (${h.quantity})',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, InventoryProductDetail product) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Issue'),
            onPressed: () => context
                .push('/sales/report-issue?productNumber=${product.productNumber}'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.error),
              foregroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Suggest Update',
                style: TextStyle(color: Colors.white)),
            onPressed: () => context.push(
                '/sales/suggest-update?productNumber=${product.productNumber}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Out of Stock':
        return theme.colorScheme.error;
      case 'Low Stock':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }
}
