import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_products_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setProductListHeader();
    });
  }

  void _setProductListHeader() {
    ref
        .read(shellLayoutProvider.notifier)
        .update(
          title: 'Inventory Dashboard',
          actions: [],
          breadcrumbs: ['Inventory', 'Products'],
        );
  }

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
                        final isWarningFilterActive =
                            state.warningFilter != null &&
                            state.warningFilter != 'NONE';
                        return EmptyView(
                          icon: isWarningFilterActive
                              ? Icons.warning_amber_rounded
                              : Icons.search_off,
                          title: isWarningFilterActive
                              ? 'No warning products found'
                              : 'No products found',
                          description: isWarningFilterActive
                              ? 'No products require attention under the selected warning filter.'
                              : 'No products match your search or filter criteria. Try clearing filters.',
                          actionLabel: isWarningFilterActive
                              ? 'Clear Warning Filter'
                              : 'Reset Filters',
                          onActionPressed: () {
                            if (isWarningFilterActive) {
                              ref
                                  .read(inventoryProductsProvider.notifier)
                                  .setWarningFilter('NONE');
                            } else {
                              _searchController.clear();
                              ref
                                  .read(inventoryProductsProvider.notifier)
                                  .setSearchKeyword('');
                              ref
                                  .read(inventoryProductsProvider.notifier)
                                  .setCategoryNumber(null);
                            }
                          },
                        );
                      }
                      return Column(
                        children: [
                          Expanded(child: _buildTable(context, items, state)),
                          if ((state.warningFilter ?? 'NONE') == 'NONE') ...[
                            const Divider(height: 1),
                            _buildPagination(context, state),
                          ],
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
        final isWide = constraints.maxWidth >= 750;

        Widget searchColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SEARCH PRODUCTS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
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
            ),
          ],
        );

        Widget categoryColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CATEGORY FILTER',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            categoriesState.when(
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (err, stack) => const SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Error loading categories',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
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
            ),
          ],
        );

        Widget purchaseSelectedButton = SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              final selectedProds = ref
                  .read(inventoryProductsProvider)
                  .selectedProductNumbers;
              if (selectedProds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Please select at least one product from the table first.',
                    ),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(inventoryProductsProvider.notifier)
                    .submitPurchaseRequest();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Products have been added to the purchase request.',
                      ),
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
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              foregroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.shopping_basket_outlined, size: 20),
            label: const Text(
              'Purchase Selected',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

        Widget addNewProductButton = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () async {
              final hasChanged = await context.push<bool>(
                '/stock/products/add',
              );
              if (!context.mounted) return;
              _setProductListHeader();
              if (hasChanged == true) {
                ref.read(inventoryProductsProvider.notifier).loadProducts();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Add New Product',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: searchColumn),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: categoryColumn),
              const SizedBox(width: 16),
              purchaseSelectedButton,
              const SizedBox(width: 16),
              addNewProductButton,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchColumn,
              const SizedBox(height: 16),
              categoryColumn,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: purchaseSelectedButton),
                  const SizedBox(width: 16),
                  Expanded(child: addNewProductButton),
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
              final selectedProds = ref
                  .read(inventoryProductsProvider)
                  .selectedProductNumbers;
              if (selectedProds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please select at least one product.'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(inventoryProductsProvider.notifier)
                    .submitPurchaseRequest();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Products have been added to the purchase request.',
                      ),
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

  Widget _buildWarningBadges(
    BuildContext context,
    InventoryProduct item,
    bool isLowStock,
    bool isNearExpiry,
    bool isExpired,
  ) {
    final theme = Theme.of(context);
    final badges = <Widget>[];

    if (isExpired) {
      final dateStr = item.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
          : 'Unknown';
      badges.add(
        _buildSmallBadge(
          context: context,
          icon: Icons.cancel_outlined,
          label: 'Expired ($dateStr)',
          backgroundColor: theme.colorScheme.errorContainer.withValues(
            alpha: 0.8,
          ),
          textColor: theme.colorScheme.onErrorContainer,
        ),
      );
    } else if (isNearExpiry) {
      final dateStr = item.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
          : 'Unknown';
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(
        item.expiryDate!.year,
        item.expiryDate!.month,
        item.expiryDate!.day,
      );
      final daysRemaining = expiry.difference(today).inDays;
      final labelStr = daysRemaining == 0
          ? 'Expiring today'
          : 'Expiring in $daysRemaining d ($dateStr)';

      badges.add(
        _buildSmallBadge(
          context: context,
          icon: Icons.warning_amber_rounded,
          label: labelStr,
          backgroundColor: Colors.amber.shade100,
          textColor: Colors.amber.shade900,
        ),
      );
    }

    if (isLowStock) {
      badges.add(
        _buildSmallBadge(
          context: context,
          icon: Icons.unfold_more_double_rounded,
          label:
              'Low Stock (${item.stock.toStringAsFixed(0)} < ${item.reorderLevel.toStringAsFixed(0)})',
          backgroundColor: theme.colorScheme.primaryContainer.withValues(
            alpha: 0.8,
          ),
          textColor: theme.colorScheme.onPrimaryContainer,
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(spacing: 4, runSpacing: 4, children: badges),
    );
  }

  Widget _buildSmallBadge({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
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
    final activeOnPage = items
        .where((e) => e.status == 'ACTIVE')
        .map((e) => e.productNumber)
        .toSet();
    final isAllSelectedOnPage =
        activeOnPage.isNotEmpty &&
        state.selectedProductNumbers.containsAll(activeOnPage);

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
              dataRowMinHeight: 56,
              dataRowMaxHeight: 88,
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 24,
                    child: Checkbox(
                      value: isAllSelectedOnPage,
                      onChanged: activeOnPage.isNotEmpty
                          ? (val) {
                              ref
                                  .read(inventoryProductsProvider.notifier)
                                  .selectAll(items);
                            }
                          : null,
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

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final isExpired =
                    item.expiryDate != null &&
                    DateTime(
                      item.expiryDate!.year,
                      item.expiryDate!.month,
                      item.expiryDate!.day,
                    ).isBefore(today);
                final isNearExpiry =
                    item.expiryDate != null &&
                    !isExpired &&
                    !DateTime(
                      item.expiryDate!.year,
                      item.expiryDate!.month,
                      item.expiryDate!.day,
                    ).isAfter(
                      today.add(Duration(days: item.expiryWarningDays)),
                    );

                final isInactive = item.status != 'ACTIVE';

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: isInactive
                      ? null
                      : (val) {
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
                          onChanged: isInactive
                              ? null
                              : (val) {
                                  ref
                                      .read(inventoryProductsProvider.notifier)
                                      .toggleProductSelection(
                                        item.productNumber,
                                      );
                                },
                        ),
                      ),
                    ),
                    DataCell(
                      Opacity(
                        opacity: isInactive ? 0.5 : 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.barcode,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  _buildWarningBadges(
                                    context,
                                    item,
                                    isLowStock,
                                    isNearExpiry,
                                    isExpired,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    DataCell(
                      Opacity(
                        opacity: isInactive ? 0.5 : 1.0,
                        child: Text(item.categoryName),
                      ),
                    ),
                    DataCell(
                      Opacity(
                        opacity: isInactive ? 0.5 : 1.0,
                        child: Column(
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
                    ),
                    DataCell(
                      Opacity(
                        opacity: isInactive ? 0.5 : 1.0,
                        child: Text(currencyFormat.format(item.sellingPrice)),
                      ),
                    ),
                    DataCell(
                      Opacity(
                        opacity: isInactive ? 0.5 : 1.0,
                        child: Text(
                          item.status == 'ACTIVE' ? 'Active' : 'Deactive',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined),
                            tooltip: 'View details',
                            onPressed: () async {
                              final hasChanged = await context.push<bool>(
                                '/stock/products/detail/${item.productNumber}',
                              );
                              if (!context.mounted) return;
                              _setProductListHeader();
                              if (hasChanged == true) {
                                await ref
                                    .read(inventoryProductsProvider.notifier)
                                    .loadProducts();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit product',
                            onPressed: () async {
                              final hasChanged = await context.push<bool>(
                                '/stock/products/edit/${item.productNumber}',
                                extra: item,
                              );
                              if (!context.mounted) return;
                              _setProductListHeader();
                              if (hasChanged == true) {
                                await ref
                                    .read(inventoryProductsProvider.notifier)
                                    .loadProducts();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            tooltip: 'Add to purchase request',
                            onPressed: isInactive
                                ? null
                                : () async {
                                    try {
                                      await ref
                                          .read(
                                            inventoryProductsProvider.notifier,
                                          )
                                          .submitPurchaseRequestForSingleProduct(
                                            item.productNumber,
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Products have been added to the purchase request.',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Purchase request failed: $e',
                                            ),
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
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
                            onPressed: () =>
                                _showStatusToggleConfirmation(context, item),
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
    final displayTotalPages = state.totalPages == 0 ? 1 : state.totalPages;
    final canPrev = currentPage > 0;
    final canNext = currentPage < displayTotalPages - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: canPrev
                      ? () => ref
                            .read(inventoryProductsProvider.notifier)
                            .setPage(currentPage - 1)
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: canPrev
                          ? theme.colorScheme.outlineVariant
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Prev',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canPrev
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Page [${currentPage + 1}] of $displayTotalPages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: canNext
                      ? () => ref
                            .read(inventoryProductsProvider.notifier)
                            .setPage(currentPage + 1)
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: canNext
                          ? theme.colorScheme.outlineVariant
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canNext
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Text(
                '© 2024 Inventory Staff Tooling - Built for [Internal Stakeholder Review]',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_box_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Requirement Validated',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Draft State',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStatusToggleConfirmation(
    BuildContext context,
    InventoryProduct product,
  ) {
    final theme = Theme.of(context);
    final isActivating = product.status != 'ACTIVE';
    final actionText = isActivating ? 'activate' : 'deactivate';
    final actionTitle = isActivating ? 'Activate' : 'Deactivate';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isActivating
                    ? Icons.check_circle_outline
                    : Icons.power_settings_new_rounded,
                color: isActivating ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text('Confirm $actionTitle'),
            ],
          ),
          content: Text(
            'Are you sure you want to $actionText product "${product.productName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isActivating
                    ? Colors.green
                    : theme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(inventoryProductsProvider.notifier)
                      .toggleProductStatus(
                        product.productNumber,
                        product.status,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update status: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(actionTitle),
            ),
          ],
        );
      },
    );
  }
}
