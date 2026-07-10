import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_adjustment.dart';
import '../providers/dashboard_provider.dart';
import 'loading_view.dart';

class AdjustQuantityDialog extends ConsumerStatefulWidget {
  final int productNumber;

  const AdjustQuantityDialog({super.key, required this.productNumber});

  @override
  ConsumerState<AdjustQuantityDialog> createState() =>
      _AdjustQuantityDialogState();
}

class _AdjustQuantityDialogState extends ConsumerState<AdjustQuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  ProductAdjustmentData? _adjustmentData;

  String _adjustmentType = 'INCREASE'; // "INCREASE" or "DECREASE"
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProductAdjustmentData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadProductAdjustmentData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.fetchProductAdjustmentData(
        widget.productNumber,
      );
      setState(() {
        _adjustmentData = data;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to load product data: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoadingData = false;
      });
    }
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    if (qty <= 0) {
      setState(() {
        _errorMessage = 'Quantity must be greater than zero.';
      });
      return;
    }

    if (_adjustmentType == 'DECREASE' && _adjustmentData != null) {
      if (qty > _adjustmentData!.availableQuantity) {
        setState(() {
          _errorMessage = 'Insufficient inventory. Adjustment rejected.';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final success = await apiService.adjustProductQuantity(
        productNumber: widget.productNumber,
        adjustmentType: _adjustmentType,
        quantity: qty,
        reason: _reasonController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to adjust quantity. Please try again.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingData) {
      return const AlertDialog(
        content: SizedBox(height: 150, child: Center(child: LoadingView())),
      );
    }

    if (_adjustmentData == null && _errorMessage != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(_errorMessage!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final data = _adjustmentData!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.tune, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Adjust Product Quantity'),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info block
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Product', data.productName),
                      const SizedBox(height: 6),
                      _buildInfoRow('Barcode', data.barcode),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        'Current Stock',
                        '${data.availableQuantity.toStringAsFixed(0)} ${data.unitName}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.2,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Adjustment Type
                Text(
                  'Adjustment Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Increase (+)')),
                        selected: _adjustmentType == 'INCREASE',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _adjustmentType = 'INCREASE';
                              _errorMessage = null;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Decrease (-)')),
                        selected: _adjustmentType == 'DECREASE',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _adjustmentType = 'DECREASE';
                              _errorMessage = null;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quantity input
                Text(
                  'Quantity to Adjust (${data.unitName})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter adjustment quantity.';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Quantity must be a positive number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reason input
                Text(
                  'Reason for Adjustment',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter reason (e.g. damaged, audit discrepancy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reason for this adjustment.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitAdjustment,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
