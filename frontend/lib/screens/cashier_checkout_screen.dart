import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/cashier_format.dart';
import '../models/cashier_models.dart';
import '../providers/cashier_provider.dart';
import '../providers/shell_layout_provider.dart';

class CashierCheckoutScreen extends ConsumerStatefulWidget {
  final int invoiceNumber;

  const CashierCheckoutScreen({
    super.key,
    required this.invoiceNumber,
  });

  @override
  ConsumerState<CashierCheckoutScreen> createState() =>
      _CashierCheckoutScreenState();
}

class _CashierCheckoutScreenState
    extends ConsumerState<CashierCheckoutScreen> {
  final _phoneController = TextEditingController();
  final _rewardController = TextEditingController(text: '0');
  final _paidController = TextEditingController();

  CashierInvoice? _invoice;
  CheckoutPreview? _preview;
  List<CashierPromotion> _promotions = const [];
  CashierCustomer? _customer;
  int? _promotionNumber;
  String _paymentMethod = 'CASH';
  bool _loading = true;
  bool _busy = false;
  bool _searchingCustomer = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _rewardController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  int get _rewardPoints =>
      int.tryParse(_rewardController.text.trim()) ?? 0;

  double get _paidAmount =>
      double.tryParse(_paidController.text.trim().replaceAll(',', '')) ?? 0;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(cashierApiServiceProvider);
      final invoice = await api.invoice(widget.invoiceNumber);
      if (!invoice.isUnpaid) {
        if (!mounted) return;
        context.go('/cashier/invoices/${invoice.invoiceNumber}');
        return;
      }
      if (invoice.items.isEmpty) {
        throw Exception('Add at least one product before checkout.');
      }
      final promotions = await api.promotions(widget.invoiceNumber);
      final preview = await api.previewCheckout(
        invoiceNumber: widget.invoiceNumber,
        customerNumber: invoice.customer?.customerNumber,
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _customer = invoice.customer;
        _promotions = promotions;
        _preview = preview;
        _paidController.text = preview.finalAmount.toStringAsFixed(0);
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

  Future<void> _refreshPreview() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await ref
          .read(cashierApiServiceProvider)
          .previewCheckout(
            invoiceNumber: widget.invoiceNumber,
            customerNumber: _customer?.customerNumber,
            promotionNumber: _promotionNumber,
            rewardPoints: _rewardPoints,
          );
      if (!mounted) return;
      setState(() {
        _invoice = preview.invoice;
        _preview = preview;
        if (_paymentMethod != 'CASH' || _paidController.text.trim().isEmpty) {
          _paidController.text = preview.finalAmount.toStringAsFixed(0);
        }
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _searchCustomer() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Enter a phone number first.');
      return;
    }
    setState(() {
      _searchingCustomer = true;
      _error = null;
    });
    try {
      final api = ref.read(cashierApiServiceProvider);
      final customer = await api.searchCustomer(phone);
      await api.linkCustomer(widget.invoiceNumber, customer.customerNumber);
      if (!mounted) return;
      ref.read(cashierDataVersionProvider.notifier).state++;
      setState(() {
        _customer = customer;
        _rewardController.text = '0';
        _searchingCustomer = false;
      });
      await _refreshPreview();
    } catch (error) {
      if (!mounted) return;
      setState(() => _searchingCustomer = false);
      final message = _clean(error);
      if (message.toLowerCase().contains('not found')) {
        final created = await _showRegisterCustomerDialog(phone);
        if (created != null) {
          await ref
              .read(cashierApiServiceProvider)
              .linkCustomer(widget.invoiceNumber, created.customerNumber);
          if (!mounted) return;
          ref.read(cashierDataVersionProvider.notifier).state++;
          setState(() {
            _customer = created;
            _rewardController.text = '0';
          });
          await _refreshPreview();
        }
      } else {
        setState(() => _error = message);
      }
    }
  }

  Future<CashierCustomer?> _showRegisterCustomerDialog(String phone) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: phone);
    String? dialogError;
    bool saving = false;

    final result = await showDialog<CashierCustomer>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register New Customer'),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No customer was found. Create a customer record and attach it to this invoice.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final number = phoneController.text.trim();
                          if (name.isEmpty || number.isEmpty) {
                            setDialogState(() {
                              dialogError =
                                  'Full name and phone number are required.';
                            });
                            return;
                          }
                          setDialogState(() {
                            saving = true;
                            dialogError = null;
                          });
                          try {
                            final customer = await ref
                                .read(cashierApiServiceProvider)
                                .registerCustomer(name, number);
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(customer);
                          } catch (error) {
                            setDialogState(() {
                              saving = false;
                              dialogError = _clean(error);
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    return result;
  }

  Future<void> _removeCustomer() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(cashierApiServiceProvider)
          .linkCustomer(widget.invoiceNumber, null);
      if (!mounted) return;
      ref.read(cashierDataVersionProvider.notifier).state++;
      setState(() {
        _customer = null;
        _promotionNumber = null;
        _rewardController.text = '0';
        _phoneController.clear();
        _busy = false;
      });
      await _refreshPreview();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _pay() async {
    final preview = _preview;
    if (preview == null || _busy) return;
    final paidAmount = _paymentMethod == 'CASH'
        ? _paidAmount
        : preview.finalAmount;
    if (paidAmount < preview.finalAmount) {
      _showMessage('Paid amount is lower than the invoice total.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Process ${formatMoney(preview.finalAmount)} by '
          '${_paymentMethodLabel(_paymentMethod)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final receipt = await ref
          .read(cashierApiServiceProvider)
          .processPayment(
            invoiceNumber: widget.invoiceNumber,
            customerNumber: _customer?.customerNumber,
            promotionNumber: _promotionNumber,
            rewardPoints: _rewardPoints,
            paymentMethod: _paymentMethod,
            paidAmount: paidAmount,
          );
      if (!mounted) return;
      ref.read(cashierDataVersionProvider.notifier).state++;
      context.go(
        '/cashier/receipt/${widget.invoiceNumber}',
        extra: receipt,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _clean(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Checkout',
            breadcrumbs: ['Cashier', 'Checkout'],
            actions: [
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => context.go('/cashier/pos/${widget.invoiceNumber}'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to POS'),
              ),
            ],
          );
    });

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _invoice == null
            ? _fatalError()
            : _content();
  }

  Widget _content() {
    final invoice = _invoice!;
    final preview = _preview;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;
        final left = _checkoutOptions(invoice);
        final right = _orderSummary(invoice, preview);
        if (desktop) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: 20),
                SizedBox(width: 410, child: right),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [left, const SizedBox(height: 16), right],
        );
      },
    );
  }

  Widget _checkoutOptions(CashierInvoice invoice) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (_error != null) ...[
          _errorBanner(_error!),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  Icons.person_search_outlined,
                  'Customer',
                  'Search by phone or register a new customer.',
                ),
                const SizedBox(height: 18),
                if (_customer == null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
                          ],
                          onSubmitted: (_) => _searchCustomer(),
                          decoration: const InputDecoration(
                            labelText: 'Customer phone number',
                            hintText: 'Enter phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _searchingCustomer || _busy
                              ? null
                              : _searchCustomer,
                          icon: _searchingCustomer
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search_rounded),
                          label: const Text('Search'),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            _customer!.fullName.isEmpty
                                ? '?'
                                : _customer!.fullName[0].toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _customer!.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${_customer!.phone} · ${_customer!.point} reward points',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove customer',
                          onPressed: _busy ? null : _removeCustomer,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  Icons.local_offer_outlined,
                  'Discounts',
                  'Choose one eligible promotion and optionally redeem points.',
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<int>(
                  key: ValueKey(_promotionNumber ?? 0),
                  initialValue: _promotionNumber ?? 0,
                  decoration: const InputDecoration(
                    labelText: 'Promotion',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text('No promotion'),
                    ),
                    ..._promotions.map(
                      (promotion) => DropdownMenuItem<int>(
                        value: promotion.promotionNumber,
                        child: Text(
                          '${promotion.promotionName} '
                          '(${promotion.discountPercent.toStringAsFixed(0)}% · '
                          '${formatMoney(promotion.discountAmount)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() {
                            _promotionNumber = value == null || value == 0
                                ? null
                                : value;
                          });
                        },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _rewardController,
                  enabled: _customer != null && !_busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Reward points to use',
                    prefixIcon: const Icon(Icons.stars_outlined),
                    helperText: _customer == null
                        ? 'Select a customer to redeem points.'
                        : 'Available: ${_customer!.point} points · 1 point = ₫100',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _refreshPreview,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Apply and Recalculate'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(
                  Icons.payments_outlined,
                  'Payment',
                  'Select a method and confirm the received amount.',
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final selector = SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'CASH',
                          icon: Icon(Icons.payments_outlined),
                          label: Text('Cash'),
                        ),
                        ButtonSegment(
                          value: 'CARD',
                          icon: Icon(Icons.credit_card_outlined),
                          label: Text('Card'),
                        ),
                        ButtonSegment(
                          value: 'BANK_TRANSFER',
                          icon: Icon(Icons.account_balance_wallet_outlined),
                          label: Text('Bank Transfer'),
                        ),
                      ],
                      selected: {_paymentMethod},
                      onSelectionChanged: _busy
                          ? null
                          : (values) {
                              setState(() {
                                _paymentMethod = values.first;
                                if (_paymentMethod != 'CASH' &&
                                    _preview != null) {
                                  _paidController.text = _preview!
                                      .finalAmount
                                      .toStringAsFixed(0);
                                }
                              });
                            },
                    );

                    if (constraints.maxWidth >= 560) {
                      return selector;
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 560),
                        child: selector,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  enabled: _paymentMethod == 'CASH' && !_busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Paid amount',
                    prefixText: '₫ ',
                    helperText: _paymentMethod == 'CASH'
                        ? 'Enter the amount received from the customer.'
                        : 'The exact invoice amount will be charged.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderSummary(
    CashierInvoice invoice,
    CheckoutPreview? preview,
  ) {
    final finalAmount = preview?.finalAmount ?? invoice.totalAmount;
    final paid = _paymentMethod == 'CASH' ? _paidAmount : finalAmount;
    final change = (paid - finalAmount).clamp(0, double.infinity).toDouble();
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Invoice #${invoice.invoiceNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...invoice.items.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${line.productName}\n'
                        '${line.quantity.toStringAsFixed(0)} × '
                        '${formatMoney(line.unitPrice)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatMoney(line.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            _amountRow('Subtotal', invoice.totalAmount),
            _amountRow(
              'Promotion',
              -(preview?.promotion?.discountAmount ?? 0),
              negative: true,
            ),
            _amountRow(
              'Reward points',
              -(preview?.rewardDiscount ?? 0),
              negative: true,
            ),
            const Divider(height: 28),
            _amountRow('Final total', finalAmount, emphasize: true),
            if (_paymentMethod == 'CASH') ...[
              const SizedBox(height: 8),
              _amountRow('Cash received', paid),
              _amountRow('Change', change, emphasize: true),
            ],
            if (preview != null && _customer != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Estimated points earned: ${preview.estimatedPointsEarned}',
                  style: const TextStyle(
                    color: Color(0xFF16794A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy || preview == null ? null : _pay,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline_rounded),
                label: Text(
                  _busy
                      ? 'Processing...'
                      : 'Pay ${formatMoney(finalAmount)}',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Stock and customer points are updated only after payment succeeds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE2F1EC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountRow(
    String label,
    num value, {
    bool negative = false,
    bool emphasize = false,
  }) {
    final theme = Theme.of(context);
    final display = negative && value != 0
        ? '-${formatMoney(value.abs())}'
        : formatMoney(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            display,
            style: (emphasize
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              color: negative && value != 0
                  ? const Color(0xFF16794A)
                  : null,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
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
          Expanded(child: Text(message)),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () => setState(() => _error = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _fatalError() {
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

  String _paymentMethodLabel(String value) => switch (value) {
        'CARD' => 'Card',
        'BANK_TRANSFER' => 'Bank Transfer',
        _ => 'Cash',
      };

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
