import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Sales Associate product list — same management-table layout as the stock
/// role's Product Management screen, but read-only actions (view / report
/// issue / suggest update).
class SalesProductListScreen extends ConsumerStatefulWidget {
  const SalesProductListScreen({super.key});

  @override
  ConsumerState<SalesProductListScreen> createState() =>
      _SalesProductListScreenState();
}

class _SalesProductListScreenState
    extends ConsumerState<SalesProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  String _statusFilter = 'ALL';
  late Future<List<InventoryProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setHeader();
    });
  }

  void _setHeader() {
    ref.read(shellLayoutProvider.notifier).update(
          title: 'Product List',
          actions: [],
          breadcrumbs: ['Sales', 'Products'],
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<List<InventoryProduct>> _loadProducts() async {
    final data = await ApiService().fetchInventoryProducts(size: 100);
    return (data['items'] as List<InventoryProduct>)
        .where((p) => p.status == 'ACTIVE')
        .toList();
  }

  void _reload() {
    setState(() => _productsFuture = _loadProducts());
  }

  bool _isExpired(InventoryProduct p) {
    if (p.expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day)
        .isBefore(today);
  }

  bool _isNearExpiry(InventoryProduct p) {
    if (p.expiryDate == null || _isExpired(p)) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !DateTime(
            p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day)
        .isAfter(today.add(Duration(days: p.expiryWarningDays)));
  }

  bool _matchesFilter(InventoryProduct p) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty &&
        !p.productName.toLowerCase().contains(query) &&
        !p.barcode.toLowerCase().contains(query)) {
      return false;
    }
    switch (_statusFilter) {
      case 'EXPIRED':
        return _isExpired(p);
      case 'NEAR_EXPIRY':
        return _isNearExpiry(p);
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: isMobile ? 12 : 24),
          Expanded(
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: FutureBuilder<List<InventoryProduct>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  if (snapshot.hasError) {
                    return ErrorView(
                      title: 'Product data cannot be loaded.',
                      description: snapshot.error
                          .toString()
                          .replaceAll('Exception: ', ''),
                      onRetry: _reload,
                    );
                  }

                  final items =
                      (snapshot.data ?? []).where(_matchesFilter).toList();
                  if (items.isEmpty) {
                    return EmptyView(
                      icon: _statusFilter == 'ALL'
                          ? Icons.search_off
                          : Icons.warning_amber_rounded,
                      title: 'No products found',
                      description:
                          'No products match your search or filter criteria. Try clearing filters.',
                      actionLabel: 'Reset Filters',
                      onActionPressed: () {
                        _searchController.clear();
                        setState(() => _statusFilter = 'ALL');
                        _reload();
                      },
                    );
                  }
                  return isMobile
                      ? _buildMobileList(context, items)
                      : _buildTable(context, items);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
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
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (val) => setState(() {}),
          ),
        );

        Widget statusDropdown = SizedBox(
          height: 48,
          child: DropdownButtonFormField<String>(
            initialValue: _statusFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Products')),
              DropdownMenuItem(
                  value: 'NEAR_EXPIRY', child: Text('Near Expiry')),
              DropdownMenuItem(value: 'EXPIRED', child: Text('Expired')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 2, child: searchField),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: statusDropdown),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 16),
              statusDropdown,
            ],
          );
        }
      },
    );
  }

  /// Mobile layout: vertical card list instead of the data table.
  Widget _buildMobileList(BuildContext context, List<InventoryProduct> items) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDetail(context, item.productNumber),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 56,
                            height: 56,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image,
                                size: 28, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined,
                              size: 28, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.categoryName} • ${item.barcode}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(item.sellingPrice),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _mobileActionButton(
                            theme,
                            icon: Icons.report_problem_outlined,
                            label: 'Report',
                            onTap: () async {
                              await context.push(
                                  '/sales/report-issue?productNumber=${item.productNumber}');
                              if (!context.mounted) return;
                              _setHeader();
                            },
                          ),
                          const SizedBox(width: 8),
                          _mobileActionButton(
                            theme,
                            icon: Icons.edit_note_outlined,
                            label: 'Suggest',
                            onTap: () async {
                              await context.push(
                                  '/sales/suggest-update?productNumber=${item.productNumber}');
                              if (!context.mounted) return;
                              _setHeader();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<InventoryProduct> items) {
    final theme = Theme.of(context);

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
              columns: const [
                DataColumn(label: Text('Product Name')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Actions')),
              ],
              rows: items.map((item) {
                return DataRow(
                  onSelectChanged: (_) =>
                      _openDetail(context, item.productNumber),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image,
                                          size: 32, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.image_outlined,
                                  size: 32, color: Colors.grey),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(item.barcode,
                                  style: theme.textTheme.labelSmall),
                              _buildWarningBadges(context, item),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(item.categoryName)),
                    DataCell(Text(currencyFormat.format(item.sellingPrice))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined),
                            tooltip: 'View details',
                            onPressed: () =>
                                _openDetail(context, item.productNumber),
                          ),
                          IconButton(
                            icon: const Icon(Icons.report_problem_outlined),
                            tooltip: 'Report issue',
                            onPressed: () async {
                              await context.push(
                                  '/sales/report-issue?productNumber=${item.productNumber}');
                              if (!context.mounted) return;
                              _setHeader();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note_outlined),
                            tooltip: 'Suggest update',
                            onPressed: () async {
                              await context.push(
                                  '/sales/suggest-update?productNumber=${item.productNumber}');
                              if (!context.mounted) return;
                              _setHeader();
                            },
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

  Future<void> _openDetail(BuildContext context, int productNumber) async {
    await context.push('/sales/products/$productNumber');
    if (!context.mounted) return;
    _setHeader();
    _reload();
  }

  Widget _buildWarningBadges(BuildContext context, InventoryProduct item) {
    final theme = Theme.of(context);
    final badges = <Widget>[];

    if (_isExpired(item)) {
      final dateStr = item.expiryDate != null
          ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
          : 'Unknown';
      badges.add(_buildSmallBadge(
        context: context,
        icon: Icons.cancel_outlined,
        label: 'Expired ($dateStr)',
        backgroundColor:
            theme.colorScheme.errorContainer.withValues(alpha: 0.8),
        textColor: theme.colorScheme.onErrorContainer,
      ));
    } else if (_isNearExpiry(item)) {
      final dateStr = DateFormat('yyyy-MM-dd').format(item.expiryDate!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(item.expiryDate!.year, item.expiryDate!.month,
          item.expiryDate!.day);
      final daysRemaining = expiry.difference(today).inDays;
      badges.add(_buildSmallBadge(
        context: context,
        icon: Icons.warning_amber_rounded,
        label: daysRemaining == 0
            ? 'Expiring today'
            : 'Expiring in $daysRemaining d ($dateStr)',
        backgroundColor: Colors.amber.shade100,
        textColor: Colors.amber.shade900,
      ));
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
}
