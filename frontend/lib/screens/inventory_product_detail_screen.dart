import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product_detail.dart';
import '../services/api_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/status_chip.dart';
import '../widgets/adjust_quantity_dialog.dart';

final productDetailsProvider =
    StateNotifierProvider.family<
      ProductDetailsNotifier,
      AsyncValue<InventoryProductDetail>,
      int
    >((ref, productNumber) {
      final apiService = ref.watch(apiServiceProvider);
      return ProductDetailsNotifier(apiService, productNumber);
    });

class ProductDetailsNotifier
    extends StateNotifier<AsyncValue<InventoryProductDetail>> {
  final ApiService _apiService;
  final int _productNumber;

  ProductDetailsNotifier(this._apiService, this._productNumber)
    : super(const AsyncValue.loading()) {
    loadDetails();
  }

  Future<void> loadDetails() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.fetchProductDetails(_productNumber);
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

class InventoryProductDetailScreen extends ConsumerStatefulWidget {
  final int productNumber;

  const InventoryProductDetailScreen({super.key, required this.productNumber});

  @override
  ConsumerState<InventoryProductDetailScreen> createState() =>
      _InventoryProductDetailScreenState();
}

class _InventoryProductDetailScreenState
    extends ConsumerState<InventoryProductDetailScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  bool _hasAnyChange = false;

  void _setProductDetailHeader(String productName) {
    ref
        .read(shellLayoutProvider.notifier)
        .update(
          title: 'Product Details',
          actions: [],
          breadcrumbs: ['Inventory', 'Products', productName],
        );
  }

  @override
  void initState() {
    super.initState();
    // Initial shell update while loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: 'Product Details',
            actions: [],
            breadcrumbs: ['Inventory', 'Products', 'Loading...'],
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(
      productDetailsProvider(widget.productNumber),
    );

    ref.listen<AsyncValue<InventoryProductDetail>>(
      productDetailsProvider(widget.productNumber),
      (previous, next) {
        next.whenOrNull(
          data: (product) {
            _setProductDetailHeader(product.productName);
          },
        );
      },
    );

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(result ?? _hasAnyChange);
      },
      child: detailsState.when(
        loading: () => const LoadingView(),
        error: (error, stack) {
          final isNotFound =
              error.toString().contains('404') ||
              error.toString().toLowerCase().contains('not found');
          final description = isNotFound
              ? 'Product not found.'
              : error.toString();
          final title = isNotFound ? 'Not Found' : 'Error loading details';
          return ErrorView(
            title: title,
            description: description,
            onRetry: () {
              ref
                  .read(productDetailsProvider(widget.productNumber).notifier)
                  .loadDetails();
            },
          );
        },
        data: (product) {
          final isDesktop = MediaQuery.of(context).size.width >= 900;

          Widget buildLeftColumn() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                  color: Colors.white,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: product.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_outlined,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : const Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Stock History Section
                Text(
                  'Stock History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: product.stockHistory.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No stock history records found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFEFF3FF),
                            ),
                            columns: const [
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Action')),
                              DataColumn(
                                label: Expanded(
                                  child: Text('Qty', textAlign: TextAlign.end),
                                ),
                                numeric: true,
                              ),
                            ],
                            rows: product.stockHistory.map((item) {
                              final isQtyPositive = item.quantity > 0;
                              return DataRow(
                                cells: [
                                  DataCell(Text(item.date)),
                                  DataCell(Text(item.action)),
                                  DataCell(
                                    Text(
                                      isQtyPositive
                                          ? '+${item.quantity.toStringAsFixed(0)}'
                                          : item.quantity.toStringAsFixed(0),
                                      style: TextStyle(
                                        color: isQtyPositive
                                            ? const Color(
                                                0xFF00503e,
                                              ) // Viridian primary
                                            : (item.quantity < 0
                                                  ? theme.colorScheme.error
                                                  : theme
                                                        .colorScheme
                                                        .onSurface),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            );
          }

          Widget buildRightColumn() {
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Metadata Grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BARCODE / SKU',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.barcode,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CATEGORY',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(
                                        0xFF246955,
                                      ), // primary-container
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      product.categoryName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF00503e),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Current Stock Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3FF), // surface-container-low
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT STOCK',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    product.stock.toStringAsFixed(0),
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product.unitName} Available',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pricing and Supplier Details Table
                    Column(
                      children: [
                        _buildInfoRow(
                          'Unit Price',
                          currencyFormat.format(product.sellingPrice),
                          theme,
                        ),
                        const Divider(color: Color(0xFFE5E7EB)),
                        _buildInfoRow(
                          'Primary Supplier',
                          product.supplierName,
                          theme,
                          isHighlightValue: true,
                        ),
                        if (product.importPrice != null) ...[
                          const Divider(color: Color(0xFFE5E7EB)),
                          _buildInfoRow(
                            'Import Price',
                            currencyFormat.format(product.importPrice),
                            theme,
                          ),
                        ],
                        if (product.minimumOrderQuantity != null) ...[
                          const Divider(color: Color(0xFFE5E7EB)),
                          _buildInfoRow(
                            'Min Order Qty',
                            '${product.minimumOrderQuantity!.toStringAsFixed(0)} ${product.unitName}',
                            theme,
                          ),
                        ],
                        const Divider(color: Color(0xFFE5E7EB)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              StatusChip(
                                label: product.status == 'ACTIVE'
                                    ? 'Active'
                                    : 'Inactive',
                                type: product.status == 'ACTIVE'
                                    ? 'ACTIVE'
                                    : 'INACTIVE',
                              ),
                            ],
                          ),
                        ),
                        if (product.expiryDate != null) ...[
                          const Divider(color: Color(0xFFE5E7EB)),
                          _buildInfoRow(
                            'Expiry Date',
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(product.expiryDate!),
                            theme,
                          ),
                          const Divider(color: Color(0xFFE5E7EB)),
                          _buildInfoRow(
                            'Expiry Warning Days',
                            '${product.expiryWarningDays} days',
                            theme,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Description
                    Text(
                      'DESCRIPTION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'No description provided for this product.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Buttons Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: (constraints.maxWidth - 24) / 3 > 140
                                  ? (constraints.maxWidth - 24) / 3
                                  : double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await context.push<bool>(
                                    '/products/edit/${product.productNumber}',
                                    extra: product,
                                  );
                                  if (!context.mounted) return;
                                  _setProductDetailHeader(product.productName);
                                  if (result == true) {
                                    setState(() {
                                      _hasAnyChange = true;
                                    });
                                    ref
                                        .read(
                                          productDetailsProvider(
                                            widget.productNumber,
                                          ).notifier,
                                        )
                                        .loadDetails();
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Product'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 24) / 3 > 140
                                  ? (constraints.maxWidth - 24) / 3
                                  : double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AdjustQuantityDialog(
                                      productNumber: product.productNumber,
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    setState(() {
                                      _hasAnyChange = true;
                                    });
                                    ref
                                        .read(
                                          productDetailsProvider(
                                            widget.productNumber,
                                          ).notifier,
                                        )
                                        .loadDetails();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Stock adjusted successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.sync_alt),
                                label: const Text('Stock Adj.'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: (constraints.maxWidth - 24) / 3 > 140
                                  ? (constraints.maxWidth - 24) / 3
                                  : double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Price History feature is coming soon!',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('Price History'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF8E4E14,
                                  ), // secondary saffron
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceVariant,
                          ),
                          onPressed: () => context.pop(_hasAnyChange),
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
                    const SizedBox(height: 24),
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: buildLeftColumn()),
                              const SizedBox(width: 24),
                              Expanded(flex: 7, child: buildRightColumn()),
                            ],
                          )
                        : Column(
                            children: [
                              buildLeftColumn(),
                              const SizedBox(height: 24),
                              buildRightColumn(),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isHighlightValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlightValue
                  ? const Color(0xFF00503e)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
