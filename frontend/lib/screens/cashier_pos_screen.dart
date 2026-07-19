import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/auth_provider.dart';
import '../providers/cashier_provider.dart';
import '../providers/shell_layout_provider.dart';

class CashierPosScreen extends ConsumerStatefulWidget {
  final int? invoiceNumber;

  const CashierPosScreen({super.key, this.invoiceNumber});

  @override
  ConsumerState<CashierPosScreen> createState() => _CashierPosScreenState();
}

class _CashierPosScreenState extends ConsumerState<CashierPosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  CashierInvoice? _invoice;
  List<CashierProduct> _products = const [];
  List<CashierCategory> _categories = const [];
  int? _categoryNumber;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(cashierApiServiceProvider);
      final invoiceNumber = widget.invoiceNumber;
      final values = await Future.wait([
        if (invoiceNumber != null && invoiceNumber > 0) api.invoice(invoiceNumber),
        api.categories(),
        api.products(),
      ]);
      if (!mounted) return;
      setState(() {
        var index = 0;
        if (invoiceNumber != null && invoiceNumber > 0) {
          _invoice = values[index++] as CashierInvoice;
        }
        _categories = values[index++] as List<CashierCategory>;
        _products = values[index] as List<CashierProduct>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(cashierApiServiceProvider).products(
            keyword: _searchController.text,
            categoryNumber: _categoryNumber,
          );
      if (!mounted) return;
      setState(() => _products = products);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _mutate(Future<CashierInvoice> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final invoice = await action();
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _busy = false;
      });
      _markInvoiceDataChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  Future<void> _addProduct(CashierProduct product) async {
    if (_busy) return;
    final current = _invoice;
    if (current != null) {
      await _mutate(
        () => ref
            .read(cashierApiServiceProvider)
            .addItem(current.invoiceNumber, product.productNumber),
      );
      return;
    }

    final cashierId = ref.read(authProvider).profile?.userId;
    if (cashierId == null || cashierId.isEmpty) {
      _showError('Cashier profile is not available.');
      return;
    }

    setState(() => _busy = true);
    try {
      final invoice = await ref.read(cashierApiServiceProvider).startInvoice(
            cashierId: cashierId,
            productNumber: product.productNumber,
          );
      if (!mounted) return;
      _markInvoiceDataChanged();
      context.replace('/cashier/pos/${invoice.invoiceNumber}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  void _markInvoiceDataChanged() {
    ref.read(cashierDataVersionProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'POS / Current Invoice',
            breadcrumbs: ['Cashier', 'POS'],
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text(
                    _invoice == null
                        ? 'Draft · not saved'
                        : 'Invoice #${_invoice!.invoiceNumber}',
                  ),
                ),
              ),
            ],
          );
    });

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : _content(),
      ),
    );
  }

  Widget _content() {
    final invoice = _invoice;
    if (invoice != null && !invoice.isUnpaid) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  'This invoice is ${invoice.status.toLowerCase()} and is read-only.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(
                    '/cashier/invoices/${invoice.invoiceNumber}',
                  ),
                  child: const Text('View Invoice Details'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplitView = constraints.maxWidth >= 820;
        final productPane = _productPane();
        final invoicePane = _invoicePane(invoice);

        if (useSplitView) {
          final invoiceWidth = constraints.maxWidth >= 1150 ? 390.0 : 330.0;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: productPane),
                const SizedBox(width: 18),
                SizedBox(width: invoiceWidth, child: invoicePane),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: [
              Expanded(child: productPane),
              const SizedBox(height: 10),
              _compactInvoiceBar(invoice),
            ],
          ),
        );
      },
    );
  }

  Widget _compactInvoiceBar(CashierInvoice? invoice) {
    final theme = Theme.of(context);
    final itemCount = invoice?.items.length ?? 0;
    final subtitle = invoice == null
        ? 'Draft · select a product to create it'
        : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · '
            '${formatMoney(invoice.totalAmount)}';

    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final veryNarrow = constraints.maxWidth < 430;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice == null
                            ? 'Current Invoice'
                            : 'Invoice #${invoice.invoiceNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (veryNarrow)
                  IconButton.filled(
                    tooltip: 'View Invoice',
                    onPressed: _showInvoiceSheet,
                    icon: const Icon(Icons.receipt_long_outlined),
                  )
                else
                  FilledButton.icon(
                    onPressed: _showInvoiceSheet,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View Invoice'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showInvoiceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.90;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            height: height,
            child: _invoicePane(_invoice, modalContext: sheetContext),
          ),
        );
      },
    );
  }

  Widget _productPane() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 400),
                      _loadProducts,
                    );
                  },
                  decoration: InputDecoration(
                    labelText: 'Search products',
                    hintText: 'Product name or barcode',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );

                final categoryField = DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: ValueKey(_categoryNumber ?? 0),
                  initialValue: _categoryNumber ?? 0,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text(
                        'All categories',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem<int>(
                        value: category.categoryNumber,
                        child: Text(
                          category.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryNumber = value == null || value == 0
                          ? null
                          : value;
                    });
                    _loadProducts();
                  },
                );

                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      categoryField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: categoryField),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _products.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000
                            ? 4
                            : constraints.maxWidth >= 700
                                ? 3
                                : constraints.maxWidth >= 430
                                    ? 2
                                    : 1;
                        return GridView.builder(
                          itemCount: _products.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) =>
                              _productCard(_products[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(CashierProduct product) {
    final enabled = product.canSell && !_busy;
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? () => _addProduct(product) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF0F5F3),
                child: product.imageUrl == null || product.imageUrl!.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, size: 48)
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.inventory_2_outlined, size: 48),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    formatMoney(product.sellingPrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.expired
                        ? 'Expired'
                        : '${product.availableQuantity.toStringAsFixed(0)} available',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: product.canSell
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoicePane(
    CashierInvoice? invoice, {
    BuildContext? modalContext,
  }) {
    final theme = Theme.of(context);
    final items = invoice?.items ?? const <CashierInvoiceLine>[];
    final totalAmount = invoice?.totalAmount ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Invoice', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              invoice == null
                  ? 'Draft · not saved to the database'
                  : '#${invoice.invoiceNumber}',
              style: theme.textTheme.labelSmall,
            ),
            const Divider(height: 28),
            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 52),
                      const SizedBox(height: 10),
                      Text(
                        invoice == null
                            ? 'Select the first product to create the invoice.'
                            : 'Select a product to add it.',
                        textAlign: TextAlign.center,
                      ),
                      if (invoice == null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Leaving this screen now will not create an empty invoice.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) => _line(items[index]),
                ),
              ),
            const Divider(height: 24),
            _amountRow('Subtotal', totalAmount),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TOTAL',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: invoice == null || items.isEmpty || _busy
                  ? null
                  : () {
                      if (modalContext != null) {
                        Navigator.of(modalContext).pop();
                      }
                      context.go(
                        '/cashier/checkout/${invoice.invoiceNumber}',
                      );
                    },
              icon: const Icon(Icons.payment_rounded),
              label: const Text('Checkout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      if (modalContext != null) {
                        Navigator.of(modalContext).pop();
                      }
                      if (invoice == null) {
                        context.go('/cashier');
                      } else {
                        Future.microtask(_confirmCancel);
                      }
                    },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(invoice == null ? 'Discard Draft' : 'Cancel Invoice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(CashierInvoiceLine line) {
    final invoice = _invoice!;
    final isOnlyLine = invoice.items.length == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.productName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '${formatMoney(line.unitPrice)} / unit',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isOnlyLine
                  ? 'Cancel the invoice to remove its final product'
                  : 'Remove product',
              onPressed: _busy
                  ? null
                  : isOnlyLine
                      ? () => _showError(
                            'An invoice must keep at least one product. Cancel the invoice instead.',
                          )
                      : () => _mutate(
                            () => ref
                                .read(cashierApiServiceProvider)
                                .removeItem(
                                  invoice.invoiceNumber,
                                  line.invoiceDetailNumber,
                                ),
                          ),
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: _busy
                  ? null
                  : () {
                      final quantity = line.quantity - 1;
                      if (quantity <= 0) {
                        if (isOnlyLine) {
                          _showError(
                            'An invoice must keep at least one product. Cancel the invoice instead.',
                          );
                        } else {
                          _mutate(
                            () => ref
                                .read(cashierApiServiceProvider)
                                .removeItem(
                                  invoice.invoiceNumber,
                                  line.invoiceDetailNumber,
                                ),
                          );
                        }
                      } else {
                        _mutate(
                          () => ref
                              .read(cashierApiServiceProvider)
                              .updateItem(
                                invoice.invoiceNumber,
                                line.invoiceDetailNumber,
                                quantity,
                              ),
                        );
                      }
                    },
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            SizedBox(
              width: 54,
              child: Text(
                line.quantity.toStringAsFixed(
                  line.quantity == line.quantity.roundToDouble() ? 0 : 2,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              onPressed: _busy
                  ? null
                  : () => _mutate(
                        () => ref
                            .read(cashierApiServiceProvider)
                            .updateItem(
                              invoice.invoiceNumber,
                              line.invoiceDetailNumber,
                              line.quantity + 1,
                            ),
                      ),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
            const Spacer(),
            Text(
              formatMoney(line.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _amountRow(String label, double value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(formatMoney(value),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _confirmCancel() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel invoice?'),
        content: const Text(
          'The current unpaid invoice will be marked as cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Invoice'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final invoiceNumber = _invoice?.invoiceNumber;
    if (invoiceNumber == null) {
      if (mounted) context.go('/cashier');
      return;
    }
    await _mutate(
      () => ref
          .read(cashierApiServiceProvider)
          .cancelInvoice(invoiceNumber),
    );
    if (mounted) context.go('/cashier');
  }

  Widget _errorView() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
