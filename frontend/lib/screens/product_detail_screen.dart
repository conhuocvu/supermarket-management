import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/product.dart';
import '../widgets/bento_card.dart';
import 'inventory_issue_form.dart';
import 'product_update_form.dart';

class ProductDetailScreen extends StatelessWidget {
  final String sku;

  const ProductDetailScreen({Key? key, required this.sku}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Find the product
    final productIndex = appState.products.indexWhere((p) => p.sku == sku);
    if (productIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Not Found')),
        body: const Center(child: Text('Product details could not be found.')),
      );
    }
    final product = appState.products[productIndex];
    final statusColor = _getStatusColor(product.stockStatus, theme);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          product.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Responsive main info
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
                            _buildStockAdjustmentCard(context, appState, product),
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
                            _buildLocationMapCard(context, product),
                            const SizedBox(height: 16),
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
                      _buildStockAdjustmentCard(context, appState, product),
                      const SizedBox(height: 16),
                      _buildLocationMapCard(context, product),
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
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, Product product, Color statusColor) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(product.category),
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.sku,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  product.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  product.category,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.stockStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${product.stockCount} units left',
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

  Widget _buildStockAdjustmentCard(BuildContext context, AppState appState, Product product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stock Adjustment',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.remove),
                label: const Text('Reduce by 1'),
                onPressed: product.stockCount > 0
                    ? () {
                        appState.updateProductStock(product.sku, product.stockCount - 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Stock reduced. New count: ${product.stockCount - 1}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add by 5', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  appState.updateProductStock(product.sku, product.stockCount + 5);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock added. New count: ${product.stockCount + 5}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Layout Location & Map',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(Icons.map_outlined, color: theme.colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLocationBadge('Aisle', product.aisle, theme),
              _buildLocationBadge('Shelf', product.shelf, theme),
              _buildLocationBadge('Capacity', '${product.shelfCapacity} items', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final margin = product.retailPrice - product.costPrice;
    final marginPercentage = (margin / product.retailPrice) * 100;

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
              _buildMetricItem('Retail Price', '\$${product.retailPrice.toStringAsFixed(2)}', theme),
              _buildMetricItem('Cost Price', '\$${product.costPrice.toStringAsFixed(2)}', theme),
              _buildMetricItem('Margin', '\$${margin.toStringAsFixed(2)} (${marginPercentage.toStringAsFixed(0)}%)', theme),
              _buildMetricItem('Min Stock', '${product.minStockLevel} units', theme),
            ],
          ),
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(BuildContext context, Product product) {
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
          _buildSpecRow('Supplier', product.supplier, theme),
          const Divider(height: 12),
          _buildSpecRow('Barcode (UPC)', product.barcode, theme),
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
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Logs & Stock History',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.history.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.history[index],
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

  Widget _buildBottomButtons(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Issue'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InventoryIssueForm(prefilledSku: product.sku),
                ),
              );
            },
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
            label: const Text('Suggest Update', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductUpdateForm(prefilledSku: product.sku),
                ),
              );
            },
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dairy':
        return Icons.local_cafe;
      case 'Produce':
        return Icons.eco;
      case 'Bakery':
        return Icons.breakfast_dining;
      default:
        return Icons.shopping_basket;
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Out of Stock':
        return theme.colorScheme.error;
      case 'Low Stock':
        return theme.colorScheme.secondary;
      case 'In Stock':
      default:
        return theme.colorScheme.primary;
    }
  }
}
