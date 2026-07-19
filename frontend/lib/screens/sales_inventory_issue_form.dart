import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_product.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate inventory issue report form. Products come from the real
/// inventory API; submit posts to /api/product-reports/issues which stores the
/// report and notifies Stock Controllers.
class SalesInventoryIssueForm extends ConsumerStatefulWidget {
  final int? prefilledProductNumber;

  const SalesInventoryIssueForm({super.key, this.prefilledProductNumber});

  @override
  ConsumerState<SalesInventoryIssueForm> createState() =>
      _SalesInventoryIssueFormState();
}

class _SalesInventoryIssueFormState
    extends ConsumerState<SalesInventoryIssueForm> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<InventoryProduct>> _productsFuture;

  int? _selectedProductNumber;
  String _issueType = 'OUT_OF_STOCK';
  String _quantityText = '1';
  String _description = '';
  bool _submitting = false;

  static const _issueTypes = {
    'OUT_OF_STOCK': 'Out of Stock',
    'LOW_STOCK': 'Low Stock',
    'EXPIRED': 'Expired',
  };

  @override
  void initState() {
    super.initState();
    _selectedProductNumber = widget.prefilledProductNumber;
    _productsFuture = _loadProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Report Inventory Issue',
            breadcrumbs: ['Sales', 'Report Issue'],
          );
    });
  }

  Future<List<InventoryProduct>> _loadProducts() async {
    final data = await ApiService().fetchInventoryProducts(size: 100);
    return (data['items'] as List<InventoryProduct>)
        .where((p) => p.status == 'ACTIVE')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<InventoryProduct>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load products.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        setState(() => _productsFuture = _loadProducts()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }
          final validSelection = products
                  .any((p) => p.productNumber == _selectedProductNumber)
              ? _selectedProductNumber
              : products.first.productNumber;
          final selected =
              products.firstWhere((p) => p.productNumber == validSelection);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/sales'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Report Inventory Issue',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Product',
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: validSelection,
                          isExpanded: true,
                          decoration: _fieldDecoration(theme),
                          items: products.map((p) {
                            return DropdownMenuItem<int>(
                              value: p.productNumber,
                              child: Text(
                                '${p.barcode} - ${p.productName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedProductNumber = val),
                        ),
                        const SizedBox(height: 16),
                        Text('Issue Type', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _issueType,
                          decoration: _fieldDecoration(theme),
                          items: _issueTypes.entries
                              .map((e) => DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _issueType = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text('Quantity Impacted',
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _quantityText,
                          keyboardType: TextInputType.number,
                          decoration:
                              _fieldDecoration(theme, hint: 'Enter quantity'),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please enter quantity';
                            }
                            final num = int.tryParse(val);
                            if (num == null || num <= 0) {
                              return 'Please enter a valid positive number';
                            }
                            return null;
                          },
                          onSaved: (val) => _quantityText = val ?? '1',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Stock', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Available',
                                      style: theme.textTheme.bodySmall),
                                  Text(
                                    '${selected.stock.toStringAsFixed(0)} ${selected.unitName}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category',
                                      style: theme.textTheme.bodySmall),
                                  Text(
                                    selected.categoryName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Description / Details',
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          maxLines: 3,
                          decoration: _fieldDecoration(theme,
                              hint:
                                  'Provide details on shelf location, expiry dates, or damage levels...'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please describe the issue';
                            }
                            return null;
                          },
                          onSaved: (val) => _description = val ?? '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                          _submitting ? 'Submitting...' : 'Submit Report',
                          style: const TextStyle(color: Colors.white)),
                      onPressed: _submitting
                          ? null
                          : () => _submit(selected.productNumber),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _submit(int productNumber) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final theme = Theme.of(context);
    setState(() => _submitting = true);
    try {
      final created = await ApiService().createInventoryIssueReport(
        productNumber: productNumber,
        issueType: _issueType,
        quantity: int.parse(_quantityText),
        description: _description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Issue reported. Report #${created['reportNumber']} sent to Stock Controller.'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
      context.canPop() ? context.pop() : context.go('/sales');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration(ThemeData theme, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      fillColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
