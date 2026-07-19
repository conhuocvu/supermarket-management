import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/cashier_provider.dart';
import '../widgets/role_module_scaffold.dart';

class CashierInvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceNumber;

  const CashierInvoiceDetailScreen({
    super.key,
    required this.invoiceNumber,
  });

  @override
  ConsumerState<CashierInvoiceDetailScreen> createState() =>
      _CashierInvoiceDetailScreenState();
}

class _CashierInvoiceDetailScreenState
    extends ConsumerState<CashierInvoiceDetailScreen> {
  CashierInvoice? _invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoice = await ref
          .read(cashierApiServiceProvider)
          .invoice(widget.invoiceNumber);
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
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
    final invoice = _invoice;
    return RoleModuleScaffold(
      moduleLabel: 'Cashier Module',
      title: invoice == null
          ? 'Invoice Details'
          : 'Invoice #${invoice.invoiceNumber}',
      navigationItems: cashierNavigationItems,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _content(invoice!),
    );
  }

  Widget _content(CashierInvoice invoice) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _statusChip(invoice.status),
            Chip(
              avatar: const Icon(Icons.schedule_outlined, size: 18),
              label: Text(formatDateTime(invoice.createdDate)),
            ),
            if (invoice.paymentMethod != null)
              Chip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text(_paymentLabel(invoice.paymentMethod)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 950;
            final details = _details(invoice);
            final totals = _totals(invoice);
            if (desktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: details),
                  const SizedBox(width: 18),
                  SizedBox(width: 360, child: totals),
                ],
              );
            }
            return Column(
              children: [details, const SizedBox(height: 16), totals],
            );
          },
        ),
        const SizedBox(height: 18),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Invoice Items',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (invoice.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: Text('This invoice has no items.')),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 720) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF0F5F3),
                          ),
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Barcode')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Unit Price')),
                            DataColumn(label: Text('Line Total')),
                          ],
                          rows: invoice.items
                              .map(
                                (line) => DataRow(
                                  cells: [
                                    DataCell(Text(line.productName)),
                                    DataCell(Text(line.barcode)),
                                    DataCell(
                                      Text(line.quantity.toStringAsFixed(0)),
                                    ),
                                    DataCell(Text(formatMoney(line.unitPrice))),
                                    DataCell(Text(formatMoney(line.lineTotal))),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: invoice.items
                            .map(
                              (line) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                title: Text(line.productName),
                                subtitle: Text(
                                  '${line.quantity.toStringAsFixed(0)} × '
                                  '${formatMoney(line.unitPrice)}',
                                ),
                                trailing: Text(
                                  formatMoney(line.lineTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/cashier/invoices'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Shift Invoices'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(210, 50),
              ),
            ),
            if (invoice.isUnpaid)
              FilledButton.icon(
                onPressed: () =>
                    context.go('/cashier/pos/${invoice.invoiceNumber}'),
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('Continue Invoice'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(190, 50),
                ),
              ),
            if (invoice.isPaid)
              FilledButton.icon(
                onPressed: () =>
                    context.go('/cashier/receipt/${invoice.invoiceNumber}'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View Receipt'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 50),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _details(CashierInvoice invoice) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            _row('Invoice number', '#${invoice.invoiceNumber}'),
            _row('Created date', formatDateTime(invoice.createdDate)),
            _row('Cashier', invoice.cashierName),
            _row(
              'Customer',
              invoice.customer?.fullName ?? 'Walk-in Customer',
            ),
            if (invoice.customer != null) ...[
              _row('Phone', invoice.customer!.phone),
              _row('Current reward points', '${invoice.customer!.point}'),
            ],
            _row('Payment method', _paymentLabel(invoice.paymentMethod)),
            _row('Status', invoice.status.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _totals(CashierInvoice invoice) {
    final discount = (invoice.totalAmount - invoice.finalAmount)
        .clamp(0, double.infinity)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            _money('Subtotal', invoice.totalAmount),
            if (discount > 0)
              _money('Combined discounts', -discount, discount: true),
            const Divider(height: 26),
            _money('Final total', invoice.finalAmount, emphasize: true),
            _money('Paid amount', invoice.paidAmount),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money(
    String label,
    num value, {
    bool discount = false,
    bool emphasize = false,
  }) {
    final text = discount && value != 0
        ? '-${formatMoney(value.abs())}'
        : formatMoney(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? Theme.of(context).textTheme.titleMedium
                  : null,
            ),
          ),
          Text(
            text,
            style: (emphasize
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              color: discount ? const Color(0xFF16794A) : null,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
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
      avatar: Icon(
        value == 'PAID'
            ? Icons.check_circle_outline_rounded
            : value == 'CANCELLED'
                ? Icons.cancel_outlined
                : Icons.pending_actions_outlined,
        color: color,
        size: 18,
      ),
      label: Text(value),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }

  Widget _errorView() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentLabel(String? value) => switch (value?.toUpperCase()) {
        'CARD' => 'Card',
        'BANK_TRANSFER' => 'Bank Transfer',
        'CASH' => 'Cash',
        _ => value ?? 'Not available',
      };
}
