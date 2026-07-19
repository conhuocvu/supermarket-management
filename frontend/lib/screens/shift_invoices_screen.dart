import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/auth_provider.dart';
import '../providers/cashier_provider.dart';
import '../providers/shell_layout_provider.dart';
class ShiftInvoicesScreen extends ConsumerStatefulWidget {
  const ShiftInvoicesScreen({super.key});

  @override
  ConsumerState<ShiftInvoicesScreen> createState() =>
      _ShiftInvoicesScreenState();
}

class _ShiftInvoicesScreenState extends ConsumerState<ShiftInvoicesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  ShiftInvoicePage? _result;
  int _page = 0;
  String _status = 'ALL';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final cashierId = ref.read(authProvider).profile?.userId;
    if (cashierId == null || cashierId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Cashier profile is not available.';
      });
      return;
    }
    final targetPage = page ?? _page;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(cashierApiServiceProvider)
          .shiftInvoices(
            cashierId: cashierId,
            page: targetPage,
            keyword: _searchController.text,
            status: _status,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _page = result.page;
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

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(cashierDataVersionProvider, (previous, next) {
      if (previous != null && previous != next && mounted) {
        _load(page: 0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Shift Invoices',
            breadcrumbs: ['Cashier', 'Invoices'],
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : () => _load(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          );
    });

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 18),
              _filters(),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _errorBanner(),
              ],
              const SizedBox(height: 18),
              Expanded(child: _body()),
              const SizedBox(height: 14),
              _pagination(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final shift = _result?.shift;
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          shift != null && shift.name.startsWith('No active shift')
              ? 'Invoices created today'
              : 'Invoices created during your current shift',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (shift != null)
          Chip(
            avatar: const Icon(Icons.schedule_outlined, size: 18),
            label: Text(
              shift.name.startsWith('No active shift')
                  ? 'No active shift · showing today\'s invoices'
                  : '${shift.name} · ${formatTime(shift.startDateTime)}–'
                      '${formatTime(shift.endDateTime)}',
            ),
          ),
      ],
    );
  }

  Widget _filters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 380,
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(
                    const Duration(milliseconds: 450),
                    () => _load(page: 0),
                  );
                },
                decoration: const InputDecoration(
                  labelText: 'Search invoices',
                  hintText: 'Invoice number or customer name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            ...const {
              'ALL': 'All',
              'PAID': 'Paid',
              'UNPAID': 'Unpaid',
              'CANCELLED': 'Cancelled',
            }.entries.map(
              (entry) => FilterChip(
                label: Text(entry.value),
                selected: _status == entry.key,
                showCheckmark: false,
                onSelected: _loading
                    ? null
                    : (_) {
                        setState(() => _status = entry.key);
                        _load(page: 0);
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _result?.items ?? const <CashierInvoiceSummary>[];
    if (items.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No invoices found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text('Try changing the search text or status filter.'),
              ],
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return _table(items);
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _card(items[index]),
          ),
        );
      },
    );
  }

  Widget _table(List<CashierInvoiceSummary> items) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF0F5F3),
                      ),
                      columns: const [
                        DataColumn(label: Text('Invoice')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Subtotal')),
                        DataColumn(label: Text('Final total')),
                        DataColumn(label: Text('Payment')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('')),
                      ],
                      rows: items
                          .map(
                            (invoice) => DataRow(
                              cells: [
                                DataCell(Text('#${invoice.invoiceNumber}')),
                                DataCell(
                                  Text(formatDateTime(invoice.createdDate)),
                                ),
                                DataCell(Text(invoice.customerName)),
                                DataCell(
                                  Text(formatMoney(invoice.totalAmount)),
                                ),
                                DataCell(
                                  Text(formatMoney(invoice.finalAmount)),
                                ),
                                DataCell(
                                  Text(_paymentLabel(invoice.paymentMethod)),
                                ),
                                DataCell(_statusChip(invoice.status)),
                                DataCell(
                                  IconButton(
                                    tooltip: 'View invoice details',
                                    onPressed: () => context.go(
                                      '/cashier/invoices/'
                                      '${invoice.invoiceNumber}',
                                    ),
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _card(CashierInvoiceSummary invoice) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/cashier/invoices/${invoice.invoiceNumber}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _statusChip(invoice.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(invoice.customerName),
              Text(formatDateTime(invoice.createdDate)),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(child: Text(_paymentLabel(invoice.paymentMethod))),
                  Text(
                    formatMoney(invoice.finalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pagination() {
    final result = _result;
    final page = result == null || result.totalPages == 0 ? 0 : result.page + 1;
    final totalPages = result?.totalPages ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text('${result?.totalItems ?? 0} total invoices'),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: !_loading && _page > 0
                  ? () => _load(page: _page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text('Page $page of $totalPages'),
            IconButton(
              tooltip: 'Next page',
              onPressed: !_loading && _page + 1 < totalPages
                  ? () => _load(page: _page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final value = status.toUpperCase();
    final color = switch (value) {
      'PAID' => const Color(0xFF16794A),
      'CANCELLED' => const Color(0xFFB42318),
      _ => const Color(0xFF9A6700),
    };
    return Chip(
      label: Text(value),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC9C4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _paymentLabel(String? value) => switch (value?.toUpperCase()) {
        'CARD' => 'Card',
        'BANK_TRANSFER' => 'Bank Transfer',
        'CASH' => 'Cash',
        _ => value ?? '—',
      };
}
