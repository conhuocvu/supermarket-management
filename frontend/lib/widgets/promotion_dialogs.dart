import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promotion.dart';
import '../providers/promotion_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _fieldDecoration(
  BuildContext context,
  String label,
  IconData prefixIcon, {
  String? hint,
  Widget? suffix,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(prefixIcon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );
}

Widget _errorBanner(BuildContext context, String message) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

const _statusOptions = ['ACTIVE', 'SCHEDULED', 'INACTIVE'];

String _formatDate(DateTime? d) =>
    d != null
        ? '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
        : 'Select date';

// ─────────────────────────────────────────────────────────────────────────────
// Add Promotion Dialog
// ─────────────────────────────────────────────────────────────────────────────

class AddPromotionDialog extends ConsumerStatefulWidget {
  const AddPromotionDialog({super.key});

  @override
  ConsumerState<AddPromotionDialog> createState() => _AddPromotionDialogState();
}

class _AddPromotionDialogState extends ConsumerState<AddPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _discountController = TextEditingController();
  final _codeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'ACTIVE';

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it becomes invalid
          if (_endDate != null && !_endDate!.isAfter(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      setState(() => _errorMessage = 'Please select a start date.');
      return;
    }
    if (_endDate == null) {
      setState(() => _errorMessage = 'Please select an end date.');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      setState(() => _errorMessage = 'End date must be after start date.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(promotionListProvider.notifier).createPromotion({
        'promotionName': _nameController.text.trim(),
        'discountValue': double.parse(_discountController.text.trim()),
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate!.toIso8601String().split('T').first,
        'status': _status,
        'promoCode': _codeController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Add Promotion'),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  _errorBanner(context, _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(context, 'Promotion Name', Icons.label_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Promotion name is required.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _fieldDecoration(context, 'Discount (%)', Icons.percent_rounded),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Discount value is required.';
                    final d = double.tryParse(v);
                    if (d == null || d <= 0) return 'Discount must be greater than zero.';
                    if (d > 100) return 'Discount cannot exceed 100%.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Start Date + End Date row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _fieldDecoration(context, 'Start Date', Icons.date_range_outlined),
                          child: Text(
                            _formatDate(_startDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _startDate != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _fieldDecoration(context, 'End Date', Icons.event_busy_outlined),
                          child: Text(
                            _formatDate(_endDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _endDate != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _fieldDecoration(context, 'Status', Icons.toggle_on_outlined),
                  borderRadius: BorderRadius.circular(16),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: _fieldDecoration(context, 'Promo Code (optional)', Icons.vpn_key_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _categoryController,
                  decoration: _fieldDecoration(context, 'Category (optional)', Icons.category_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _fieldDecoration(context, 'Description (optional)', Icons.notes_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create Promotion'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Promotion Dialog
// ─────────────────────────────────────────────────────────────────────────────

class EditPromotionDialog extends ConsumerStatefulWidget {
  final Promotion promotion;

  const EditPromotionDialog({super.key, required this.promotion});

  @override
  ConsumerState<EditPromotionDialog> createState() => _EditPromotionDialogState();
}

class _EditPromotionDialogState extends ConsumerState<EditPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  late final TextEditingController _nameController;
  late final TextEditingController _discountController;
  late final TextEditingController _codeController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  DateTime? _startDate;
  DateTime? _endDate;
  late String _status;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _nameController = TextEditingController(text: p.promotionName);
    _discountController = TextEditingController(text: p.discountValue.toString());
    _codeController = TextEditingController(text: p.promoCode);
    _categoryController = TextEditingController(text: p.category);
    _descriptionController = TextEditingController(text: p.description ?? '');
    _status = p.status;

    if (p.startDate != null) {
      _startDate = DateTime.tryParse(p.startDate!);
    }
    if (p.endDate != null) {
      _endDate = DateTime.tryParse(p.endDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && !_endDate!.isAfter(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      setState(() => _errorMessage = 'Please select a start date.');
      return;
    }
    if (_endDate == null) {
      setState(() => _errorMessage = 'Please select an end date.');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      setState(() => _errorMessage = 'End date must be after start date.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(promotionListProvider.notifier).updatePromotion(
        widget.promotion.promotionNumber,
        {
          'promotionName': _nameController.text.trim(),
          'discountValue': double.parse(_discountController.text.trim()),
          'startDate': _startDate!.toIso8601String().split('T').first,
          'endDate': _endDate!.toIso8601String().split('T').first,
          'status': _status,
          'promoCode': _codeController.text.trim(),
          'category': _categoryController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Edit Promotion'),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  _errorBanner(context, _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(context, 'Promotion Name', Icons.label_outline),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Promotion name is required.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _fieldDecoration(context, 'Discount (%)', Icons.percent_rounded),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Discount value is required.';
                    final d = double.tryParse(v);
                    if (d == null || d <= 0) return 'Discount must be greater than zero.';
                    if (d > 100) return 'Discount cannot exceed 100%.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _fieldDecoration(context, 'Start Date', Icons.date_range_outlined),
                          child: Text(
                            _formatDate(_startDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _startDate != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: _fieldDecoration(context, 'End Date', Icons.event_busy_outlined),
                          child: Text(
                            _formatDate(_endDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _endDate != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _statusOptions.contains(_status) ? _status : 'ACTIVE',
                  decoration: _fieldDecoration(context, 'Status', Icons.toggle_on_outlined),
                  borderRadius: BorderRadius.circular(16),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: _fieldDecoration(context, 'Promo Code', Icons.vpn_key_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _categoryController,
                  decoration: _fieldDecoration(context, 'Category', Icons.category_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _fieldDecoration(context, 'Description', Icons.notes_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deactivate Promotion Confirmation Dialog
// ─────────────────────────────────────────────────────────────────────────────

class DeactivatePromotionDialog extends ConsumerStatefulWidget {
  final Promotion promotion;

  const DeactivatePromotionDialog({super.key, required this.promotion});

  @override
  ConsumerState<DeactivatePromotionDialog> createState() =>
      _DeactivatePromotionDialogState();
}

class _DeactivatePromotionDialogState
    extends ConsumerState<DeactivatePromotionDialog> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(promotionListProvider.notifier)
          .deactivatePromotion(widget.promotion.promotionNumber);
      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.block_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          const Text('Deactivate Promotion'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            _errorBanner(context, _errorMessage!),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.promotion.promotionName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${widget.promotion.promoCode}  •  ${widget.promotion.discountValue.toStringAsFixed(1)}% off',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This promotion will be set to INACTIVE. It will no longer appear as active. This action does not delete the record.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _confirm,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Deactivate'),
        ),
      ],
    );
  }
}
