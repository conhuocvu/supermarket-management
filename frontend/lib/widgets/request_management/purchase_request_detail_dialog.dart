import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_provider.dart';
import '../../models/purchase_request.dart';
import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';

class PurchaseRequestDetailDialog extends ConsumerStatefulWidget {
  final StaffRequest request;

  const PurchaseRequestDetailDialog({super.key, required this.request});

  @override
  ConsumerState<PurchaseRequestDetailDialog> createState() =>
      _PurchaseRequestDetailDialogState();
}

class _PurchaseRequestDetailDialogState
    extends ConsumerState<PurchaseRequestDetailDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  PurchaseRequestDetail? _details;

  DateTime? _expectedDeliveryDate;
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final details = await apiService
          .fetchPurchaseRequestDetail(widget.request.requestNumber);
      setState(() {
        _details = details;
        _expectedDeliveryDate = details.expectedDeliveryDate;
        for (final item in details.items) {
          _controllers[item.productNumber] = TextEditingController(
            text: item.requestedQuantity.toStringAsFixed(0),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPending = widget.request.status.toUpperCase() == 'PENDING';

    Widget body;

    if (_isLoading) {
      body = const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_errorMessage != null) {
      body = SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load details',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      final details = _details!;
      double totalEstimatedCost = 0.0;
      double totalQuantity = 0.0;

      for (final item in details.items) {
        final controller = _controllers[item.productNumber];
        final qty = controller != null
            ? (double.tryParse(controller.text) ?? item.requestedQuantity)
            : item.requestedQuantity;
        totalQuantity += qty;
        totalEstimatedCost += qty * item.importPrice;
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expected Delivery Date Picker
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Expected Delivery Date:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              if (isPending)
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDeliveryDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    _expectedDeliveryDate == null
                        ? 'Select Date'
                        : _formatDate(_expectedDeliveryDate!),
                  ),
                )
              else
                Text(
                  _expectedDeliveryDate == null
                      ? 'Not specified'
                      : _formatDate(_expectedDeliveryDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Items Table
          _buildSectionTitle(theme, 'Requested Products'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dataRowMinHeight: 56,
                dataRowMaxHeight: 76,
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                columnSpacing: 16,
                horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('Product / SKU')),
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Stock / Reorder')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Import Cost')),
                DataColumn(label: Text('Subtotal')),
              ],
              rows: details.items.map((item) {
                final controller = _controllers[item.productNumber];
                final qty = controller != null
                    ? (double.tryParse(controller.text) ??
                        item.requestedQuantity)
                    : item.requestedQuantity;
                final subtotal = qty * item.importPrice;

                final currentStock = item.currentStock ?? 0.0;
                final reorderLevel = item.reorderLevel ?? 0.0;
                final isLowStock = currentStock <= reorderLevel;

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            item.sku,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(item.supplierName)),
                    DataCell(
                      Row(
                        children: [
                          Text(
                            '${currentStock.toStringAsFixed(0)} / ${reorderLevel.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isLowStock ? colorScheme.error : null,
                              fontWeight:
                                  isLowStock ? FontWeight.bold : null,
                            ),
                          ),
                          if (isLowStock) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                    DataCell(
                      isPending && controller != null
                          ? SizedBox(
                              width: 65,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                enabled: !_isSaving,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            )
                          : Text('${item.requestedQuantity.toStringAsFixed(0)} ${item.unitName}'),
                    ),
                    DataCell(Text('${item.importPrice.toStringAsFixed(0)} VND')),
                    DataCell(
                      Text(
                        '${subtotal.toStringAsFixed(0)} VND',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

          // Total Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items Count',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${details.items.length} items (${totalQuantity.toStringAsFixed(0)} units)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Estimated Total Cost',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalEstimatedCost.toStringAsFixed(0)} VND',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 820),
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
                          'Purchase Request Details',
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

              body,

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (isPending && !_isLoading && _errorMessage == null) ...[
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _updateStatusDirect('REJECTED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _adjustAndApprove,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ?? now.add(const Duration(days: 3)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
    );

    if (picked != null) {
      setState(() {
        _expectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _updateStatusDirect(String status) async {
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
              'Purchase request was ${status.toLowerCase()} successfully.',
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
    if (_expectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expected delivery date first.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> itemsList = [];
      for (final item in _details!.items) {
        final controller = _controllers[item.productNumber];
        final qty = controller != null
            ? (double.tryParse(controller.text) ?? item.requestedQuantity)
            : item.requestedQuantity;

        if (qty <= 0) {
          throw Exception(
            'Requested quantity for ${item.productName} must be greater than zero.',
          );
        }

        itemsList.add({
          'productNumber': item.productNumber,
          'requestedQuantity': qty,
        });
      }

      final dateStr = _formatDate(_expectedDeliveryDate!);

      await ref.read(staffRequestProvider.notifier).adjustPurchaseRequest(
            request: widget.request,
            expectedDeliveryDate: dateStr,
            status: 'APPROVED',
            items: itemsList,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchase request adjusted and approved successfully.',
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
}
