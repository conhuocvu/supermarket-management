import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';

class ClearanceDetailDialog extends ConsumerStatefulWidget {
  final StaffRequest request;

  const ClearanceDetailDialog({super.key, required this.request});

  @override
  ConsumerState<ClearanceDetailDialog> createState() =>
      _ClearanceDetailDialogState();
}

class _ClearanceDetailDialogState extends ConsumerState<ClearanceDetailDialog> {
  late double _discountPercentage;
  late TextEditingController _reasonController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _discountPercentage = widget.request.discountPercentage ?? 10.0;
    _reasonController = TextEditingController(text: widget.request.reason);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending = widget.request.status.toUpperCase() == 'PENDING';

    final sellingPrice = widget.request.sellingPrice ?? 0.0;
    final importPrice = widget.request.importPrice ?? 0.0;
    final remainingQty = widget.request.remainingQuantity ?? 0.0;

    final originalValue = sellingPrice * remainingQty;
    final proposedSellingPrice = sellingPrice * (1 - _discountPercentage / 100);
    final proposedValue = proposedSellingPrice * remainingQty;
    final marginDiffPerItem = proposedSellingPrice - importPrice;
    final isLoss = marginDiffPerItem < 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expiring Discount Request',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Request #${widget.request.requestNumber} · submitted by ${widget.request.employeeName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const Divider(height: 32),

              // Product Info Card
              _buildSectionTitle(theme, 'Product Details'),
              const SizedBox(height: 8),
              _buildDetailsGrid(context, [
                _DetailItem('Product Name', widget.request.productName ?? 'Unknown'),
                _DetailItem('Batch Number', widget.request.batchNumber ?? 'N/A'),
                _DetailItem('Remaining Quantity', remainingQty.toStringAsFixed(0)),
                _DetailItem(
                  'Original Price',
                  '${sellingPrice.toStringAsFixed(0)} VND',
                ),
                _DetailItem(
                  'Import Unit Cost',
                  '${importPrice.toStringAsFixed(0)} VND',
                ),
              ]),
              const SizedBox(height: 20),

              // Pricing & Margin Analysis Card
              _buildSectionTitle(theme, 'Financial & Margin Analysis'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isLoss
                      ? colorScheme.errorContainer.withValues(alpha: 0.1)
                      : colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLoss
                        ? colorScheme.error.withValues(alpha: 0.2)
                        : colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMarginRow(
                      'Original Retail Value',
                      '${originalValue.toStringAsFixed(0)} VND',
                    ),
                    const SizedBox(height: 8),
                    _buildMarginRow(
                      'Proposed Selling Price',
                      '${proposedSellingPrice.toStringAsFixed(0)} VND (${_discountPercentage.toStringAsFixed(0)}% off)',
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildMarginRow(
                      'Estimated Clear Value',
                      '${proposedValue.toStringAsFixed(0)} VND',
                    ),
                    const Divider(height: 16),
                    _buildMarginRow(
                      'Margin per unit',
                      '${marginDiffPerItem.toStringAsFixed(0)} VND',
                      valueColor: isLoss ? colorScheme.error : colorScheme.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Adjust Controls (Only if Pending)
              if (isPending) ...[
                _buildSectionTitle(theme, 'Adjust Proposal'),
                const SizedBox(height: 12),

                // Discount Slider
                Row(
                  children: [
                    Text(
                      'Discount percentage:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_discountPercentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _discountPercentage,
                  min: 5,
                  max: 95,
                  divisions: 18,
                  label: '${_discountPercentage.round()}%',
                  onChanged: _isSaving
                      ? null
                      : (val) {
                          setState(() {
                            _discountPercentage = val;
                          });
                        },
                ),
                const SizedBox(height: 12),

                // Reason input
                TextField(
                  controller: _reasonController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Adjust description / justification',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (isPending) ...[
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _updateStatus('REJECTED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () => _adjustAndApprove(),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save & Approve'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context, List<_DetailItem> items) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarginRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(staffRequestProvider.notifier).updateRequestStatus(
            request: widget.request,
            status: status,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clearance request was ${status.toLowerCase()} successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _adjustAndApprove() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(staffRequestProvider.notifier).adjustClearanceRequest(
            request: widget.request,
            discountPercentage: _discountPercentage,
            reason: _reasonController.text.trim(),
            status: 'APPROVED',
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount request adjusted and approved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
