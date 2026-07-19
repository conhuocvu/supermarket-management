import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/cashier_provider.dart';
import '../services/receipt_print_service.dart';
import '../providers/shell_layout_provider.dart';

class CashierReceiptScreen extends ConsumerStatefulWidget {
  final int invoiceNumber;
  final CashierReceipt? initialReceipt;

  const CashierReceiptScreen({
    super.key,
    required this.invoiceNumber,
    this.initialReceipt,
  });

  @override
  ConsumerState<CashierReceiptScreen> createState() =>
      _CashierReceiptScreenState();
}

class _CashierReceiptScreenState extends ConsumerState<CashierReceiptScreen> {
  CashierReceipt? _receipt;
  bool _loading = true;
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _receipt = widget.initialReceipt;
    _loading = _receipt == null;
    if (_receipt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final receipt = await ref
          .read(cashierApiServiceProvider)
          .receipt(widget.invoiceNumber);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _print() async {
    final receipt = _receipt;
    if (receipt == null || _printing) return;
    setState(() => _printing = true);
    try {
      await printReceipt(_receiptText(receipt));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt sent to the printer.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_clean(error))),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Receipt',
            breadcrumbs: ['Cashier', 'Receipt'],
            actions: [
              OutlinedButton.icon(
                onPressed: _receipt == null || _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
                label: const Text('Print'),
              ),
            ],
          );
    });

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _errorView()
            : _content(_receipt!);
  }

  Widget _content(CashierReceipt receipt) {
    final invoice = receipt.invoice;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F6EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB7E3C9)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF16794A),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.check_rounded, size: 30),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Successful',
                              style: TextStyle(
                                color: Color(0xFF14532D),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'The invoice, payment, stock and reward points have been updated.',
                              style: TextStyle(color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Text(
                          'SUPERMARKET MANAGEMENT SYSTEM',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sales Receipt',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Divider(height: 32),
                        _infoRow('Invoice', '#${invoice.invoiceNumber}'),
                        _infoRow('Payment date', formatDateTime(receipt.paymentDate)),
                        _infoRow('Cashier', invoice.cashierName),
                        _infoRow(
                          'Customer',
                          invoice.customer?.fullName ?? 'Walk-in Customer',
                        ),
                        if (invoice.customer != null)
                          _infoRow('Phone', invoice.customer!.phone),
                        _infoRow(
                          'Payment method',
                          _paymentLabel(invoice.paymentMethod),
                        ),
                        const Divider(height: 32),
                        ...invoice.items.map(_line),
                        const Divider(height: 32),
                        _moneyRow('Subtotal', invoice.totalAmount),
                        if (receipt.promotion != null)
                          _moneyRow(
                            'Promotion (${receipt.promotion!.promotionName})',
                            -receipt.promotion!.discountAmount,
                            discount: true,
                          ),
                        if (receipt.rewardDiscount > 0)
                          _moneyRow(
                            'Reward points (${receipt.rewardPointsUsed})',
                            -receipt.rewardDiscount,
                            discount: true,
                          ),
                        const SizedBox(height: 4),
                        _moneyRow(
                          'TOTAL',
                          invoice.finalAmount,
                          emphasize: true,
                        ),
                        _moneyRow('Paid', receipt.paidAmount),
                        _moneyRow('Change', receipt.changeAmount),
                        if (invoice.customer != null) ...[
                          const Divider(height: 32),
                          _infoRow(
                            'Points used',
                            '${receipt.rewardPointsUsed}',
                          ),
                          _infoRow('Points earned', '${receipt.pointsEarned}'),
                        ],
                        const Divider(height: 32),
                        Text(
                          'Thank you for shopping with us!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _printing ? null : _print,
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print Receipt'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(180, 52),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/cashier/new-invoice'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Invoice'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(180, 52),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/cashier/invoices'),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Shift Invoices'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(180, 52),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _line(CashierInvoiceLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${line.quantity.toStringAsFixed(0)} × '
                  '${formatMoney(line.unitPrice)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(line.lineTotal),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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

  Widget _moneyRow(
    String label,
    num value, {
    bool emphasize = false,
    bool discount = false,
  }) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: discount ? const Color(0xFF16794A) : null,
            );
    final text = discount && value != 0
        ? '-${formatMoney(value.abs())}'
        : formatMoney(value);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: emphasize ? 8 : 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(text, style: style),
        ],
      ),
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

  String _receiptText(CashierReceipt receipt) {
    final invoice = receipt.invoice;
    final buffer = StringBuffer()
      ..writeln('SUPERMARKET MANAGEMENT SYSTEM')
      ..writeln('SALES RECEIPT')
      ..writeln('----------------------------------------')
      ..writeln('Invoice: #${invoice.invoiceNumber}')
      ..writeln('Date: ${formatDateTime(receipt.paymentDate)}')
      ..writeln('Cashier: ${invoice.cashierName}')
      ..writeln('Customer: ${invoice.customer?.fullName ?? 'Walk-in Customer'}')
      ..writeln('----------------------------------------');
    for (final line in invoice.items) {
      buffer
        ..writeln(line.productName)
        ..writeln(
          '  ${line.quantity.toStringAsFixed(0)} x '
          '${formatMoney(line.unitPrice)} = ${formatMoney(line.lineTotal)}',
        );
    }
    buffer
      ..writeln('----------------------------------------')
      ..writeln('Subtotal: ${formatMoney(invoice.totalAmount)}');
    if (receipt.promotion != null) {
      buffer.writeln(
        'Promotion: -${formatMoney(receipt.promotion!.discountAmount)}',
      );
    }
    if (receipt.rewardDiscount > 0) {
      buffer.writeln(
        'Reward points: -${formatMoney(receipt.rewardDiscount)}',
      );
    }
    buffer
      ..writeln('TOTAL: ${formatMoney(invoice.finalAmount)}')
      ..writeln('Paid: ${formatMoney(receipt.paidAmount)}')
      ..writeln('Change: ${formatMoney(receipt.changeAmount)}')
      ..writeln('Method: ${_paymentLabel(invoice.paymentMethod)}')
      ..writeln('----------------------------------------')
      ..writeln('Thank you for shopping with us!');
    return buffer.toString();
  }

  String _paymentLabel(String? value) => switch (value?.toUpperCase()) {
        'CARD' => 'Card',
        'BANK_TRANSFER' => 'Bank Transfer',
        'CASH' => 'Cash',
        _ => value ?? 'Not available',
      };

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
