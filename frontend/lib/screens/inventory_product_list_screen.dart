import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_products_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/status_chip.dart';
import '../models/inventory_product.dart';
import 'package:intl/intl.dart';

class InventoryProductListScreen extends ConsumerStatefulWidget {
  const InventoryProductListScreen({super.key});

  @override
  ConsumerState<InventoryProductListScreen> createState() =>
      _InventoryProductListScreenState();
}

class _InventoryProductListScreenState
    extends ConsumerState<InventoryProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(inventoryProductsProvider);
    final categoriesState = ref.watch(categoriesListProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(title: 'Product Management', actions: []);
    });

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters & Actions Row
              _buildFilterHeader(context, state, categoriesState),
              const SizedBox(height: 24),

              // Selected Action bar if items are selected
              if (state.selectedProductNumbers.isNotEmpty) ...[
                _buildSelectedActionBar(context, state),
                const SizedBox(height: 16),
              ],

              // Products list area
              Expanded(
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: state.products.when(
                    loading: () => const LoadingView(),
                    error: (err, stack) => ErrorView(
                      title: 'Product data cannot be loaded.',
                      description: err.toString().replaceAll('Exception: ', ''),
                      onRetry: () => ref
                          .read(inventoryProductsProvider.notifier)
                          .loadProducts(),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return EmptyView(
                          icon: Icons.search_off,
                          title: 'No products found',
                          description:
                              'No products match your search or filter criteria. Try clearing filters.',
                          actionLabel: 'Reset Filters',
                          onActionPressed: () {
                            _searchController.clear();
                            ref
                                .read(inventoryProductsProvider.notifier)
                                .setSearchKeyword('');
                            ref
                                .read(inventoryProductsProvider.notifier)
                                .setCategoryNumber(null);
                          },
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: _buildTable(context, items, state)),
                          const Divider(height: 1),
                          _buildPagination(context, state),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.isSubmittingAction)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildFilterHeader(
    BuildContext context,
    InventoryProductsState state,
    AsyncValue<List<dynamic>> categoriesState,
  ) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        Widget searchField = SizedBox(
          height: 48,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products by name or barcode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(inventoryProductsProvider.notifier)
                            .setSearchKeyword('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
            onChanged: (val) {
              ref
                  .read(inventoryProductsProvider.notifier)
                  .setSearchKeyword(val);
            },
          ),
        );

        Widget categoryDropdown = categoriesState.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, stack) => const Text('Lỗi tải danh mục'),
          data: (categories) => SizedBox(
            height: 48,
            child: DropdownButtonFormField<int?>(
              key: ValueKey(state.selectedCategoryNumber),
              initialValue: state.selectedCategoryNumber,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
              hint: const Text(
                'All Categories',
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'All Categories',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.categoryNumber,
                    child: Text(
                      c.categoryName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                ref
                    .read(inventoryProductsProvider.notifier)
                    .setCategoryNumber(val);
              },
            ),
          ),
        );

        final List<Widget> actionButtons = [
          IconButton.filled(
            onPressed: () => context.go('/products/add'),
            icon: const Icon(Icons.add),
            tooltip: 'Add New Product',
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: searchField,
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: categoryDropdown,
              ),
              const SizedBox(width: 16),
              ...actionButtons,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: categoryDropdown),
                  const SizedBox(width: 16),
                  ...actionButtons,
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSelectedActionBar(
    BuildContext context,
    InventoryProductsState state,
  ) {
    final theme = Theme.of(context);
    final count = state.selectedProductNumbers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$count products selected',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () =>
                ref.read(inventoryProductsProvider.notifier).clearSelection(),
            child: const Text('Deselect All'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref
                    .read(inventoryProductsProvider.notifier)
                    .submitPurchaseRequest();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase request created successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Purchase request failed: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Purchase Selected'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List<InventoryProduct> items,
    InventoryProductsState state,
  ) {
    final theme = Theme.of(context);
    final allOnPage = items.map((e) => e.productNumber).toSet();
    final isAllSelectedOnPage = state.selectedProductNumbers.containsAll(
      allOnPage,
    );

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 320,
            ),
            child: DataTable(
            showCheckboxColumn: false,
            columns: [
              DataColumn(
                label: SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: isAllSelectedOnPage,
                    onChanged: (val) {
                      ref
                          .read(inventoryProductsProvider.notifier)
                          .selectAll(items);
                    },
                  ),
                ),
              ),
              const DataColumn(label: Text('Product Name')),
              const DataColumn(label: Text('Category')),
              const DataColumn(label: Text('Stock')),
              const DataColumn(label: Text('Price')),
              const DataColumn(label: Text('Status')),
              const DataColumn(label: Text('Actions')),
            ],
            rows: items.map((item) {
              final isSelected = state.selectedProductNumbers.contains(
                item.productNumber,
              );
              final isLowStock = item.stock <= item.reorderLevel;

              return DataRow(
                selected: isSelected,
                onSelectChanged: (val) {
                  ref
                      .read(inventoryProductsProvider.notifier)
                      .toggleProductSelection(item.productNumber);
                },
                cells: [
                  DataCell(
                    SizedBox(
                      width: 24,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          ref
                              .read(inventoryProductsProvider.notifier)
                              .toggleProductSelection(item.productNumber);
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (item.imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              item.imageUrl,
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item.barcode,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(item.categoryName)),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.stock} ${item.unitName}',
                          style: TextStyle(
                            color: isLowStock
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                            fontWeight: isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (isLowStock)
                          Text(
                            'Low stock (< ${item.reorderLevel})',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text(currencyFormat.format(item.sellingPrice))),
                  DataCell(
                    StatusChip(
                      label: item.status == 'ACTIVE' ? 'Active' : 'Inactive',
                      type: item.status == 'ACTIVE' ? 'ACTIVE' : 'INACTIVE',
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined),
                          tooltip: 'View details',
                          onPressed: () => _showProductDetails(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit product',
                          onPressed: () {
                            context.go(
                              '/products/edit/${item.productNumber}',
                              extra: item,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            item.status == 'ACTIVE'
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            color: item.status == 'ACTIVE'
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          tooltip: item.status == 'ACTIVE'
                              ? 'Deactivate product'
                              : 'Activate product',
                          onPressed: () => _showStatusToggleConfirmation(context, item),
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
  );
}

  Widget _buildPagination(BuildContext context, InventoryProductsState state) {
    final theme = Theme.of(context);
    final currentPage = state.currentPage;
    final totalPages = state.totalPages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages} (${state.totalItems} total items)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 0
                    ? () => ref
                          .read(inventoryProductsProvider.notifier)
                          .setPage(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                final isCurrent = index == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => ref
                        .read(inventoryProductsProvider.notifier)
                        .setPage(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? null
                            : Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages - 1
                    ? () => ref
                          .read(inventoryProductsProvider.notifier)
                          .setPage(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, InventoryProduct product) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.inventory, color: Colors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      'Barcode: ${product.barcode}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product.imageUrl,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  const Divider(),
                  _buildDetailRow('Category', product.categoryName),
                  _buildDetailRow('Unit', product.unitName),
                  _buildDetailRow(
                    'Price',
                    currencyFormat.format(product.sellingPrice),
                  ),
                  _buildDetailRow(
                    'Current Stock',
                    '${product.stock} ${product.unitName}',
                  ),
                  _buildDetailRow(
                    'Reorder Warning Level',
                    '${product.reorderLevel} ${product.unitName}',
                  ),
                  _buildDetailRow(
                    'Expiry Warning Days',
                    '${product.expiryWarningDays} days',
                  ),
                  _buildDetailRow(
                    'Status',
                    product.status == 'ACTIVE' ? 'Active' : 'Inactive',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'No description provided.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showStatusToggleConfirmation(BuildContext context, InventoryProduct product) {
    final theme = Theme.of(context);
    final isActivating = product.status != 'ACTIVE';
    final actionText = isActivating ? 'kích hoạt' : 'hủy kích hoạt';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isActivating ? Icons.check_circle_outline : Icons.power_settings_new_rounded,
                color: isActivating ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text('Xác nhận $actionText'),
            ],
          ),
          content: Text('Bạn có chắc chắn muốn $actionText sản phẩm "${product.productName}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isActivating ? Colors.green : theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(inventoryProductsProvider.notifier)
                      .toggleProductStatus(product.productNumber, product.status);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật trạng thái thành công.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cập nhật trạng thái thất bại: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(isActivating ? 'Kích hoạt' : 'Hủy kích hoạt'),
            ),
          ],
        );
      },
    );
  }
}
