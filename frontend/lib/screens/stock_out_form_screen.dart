import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';

class StockOutFormScreen extends ConsumerStatefulWidget {
  final int reportNumber;

  const StockOutFormScreen({
    super.key,
    required this.reportNumber,
  });

  @override
  ConsumerState<StockOutFormScreen> createState() => _StockOutFormScreenState();
}

class _StockOutFormScreenState extends ConsumerState<StockOutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isSaving = false;

  // Loaded form data
  String _productName = '';
  String _sku = '';
  double _reportedQuantity = 0.0;
  String _unitName = '';
  String _location = '';
  String _description = '';
  String _reportType = '';
  String _issueType = '';
  double _availableQuantity = 0.0;

  // Controllers for editable fields
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final String _selectedStatus = 'APPROVED'; // Read-only or preselected status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Record Stock-Out',
            actions: [],
            breadcrumbs: ['Inventory', 'Transactions', 'Record Stock-Out'],
          );
    });
    _loadFormData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchStockOutFormData(widget.reportNumber);
      setState(() {
        _productName = data['productName'] ?? 'Unknown';
        _sku = data['sku'] ?? 'N/A';
        _reportedQuantity = (data['quantity'] as num?)?.toDouble() ?? 0.0;
        _unitName = data['unitName'] ?? 'Unit';
        _location = data['location'] ?? 'N/A';
        _description = data['description'] ?? '';
        _reportType = data['reportType'] ?? '';
        _issueType = data['issueType'] ?? '';
        _availableQuantity = (data['availableQuantity'] as num?)?.toDouble() ?? 0.0;

        // Pre-fill editable controllers
        _quantityController.text = _reportedQuantity.toStringAsFixed(0);
        _reasonController.text = _issueType; // default transfer reason is the issue type
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stock-out form data: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmStockOut() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct invalid stock-out information.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final qty = double.tryParse(_quantityController.text) ?? 0.0;
      final payload = {
        'reportNumber': widget.reportNumber,
        'quantity': qty,
        'reason': _reasonController.text.trim(),
        'notes': _notesController.text.trim(),
        'createdBy': Supabase.instance.client.auth.currentUser?.id ?? 'e3b3ec4a-da0b-40f5-9747-29361993892b', // Default Stock Controller UUID from database
      };

      final success = await _apiService.submitStockOut(payload);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock-Out has been recorded successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.pop(true);
        }
      } else {
        throw Exception('Server rejected request.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock-Out cannot be recorded. ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final customInputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onPressed: () => context.pop(false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isLargeScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildInfoSection(theme),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 5,
                  child: _buildFormSection(theme, customInputDecoration),
                ),
              ],
            )
          else ...[
            _buildInfoSection(theme),
            const SizedBox(height: 32),
            _buildFormSection(theme, customInputDecoration),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    final reportColor = (_reportType == 'DAMAGED' || _reportType == 'QUALITY_ISSUE')
        ? theme.colorScheme.error
        : (_reportType == 'LOW_STOCK' ? theme.colorScheme.primary : Colors.orange);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reported Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Product Name', _productName, isBold: true),
            _buildInfoRow('SKU/Barcode', _sku),
            _buildInfoRow('Inventory Unit', _unitName),
            _buildInfoRow('Warehouse Location', _location),
            const Divider(height: 32),
            _buildInfoRow(
              'Report Type',
              _reportType,
              customBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: reportColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: reportColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _reportType,
                  style: TextStyle(
                    color: reportColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildInfoRow('Issue Type', _issueType),
            _buildInfoRow(
              'Reported Quantity',
              '${_reportedQuantity.toStringAsFixed(0)} $_unitName',
              isBold: true,
            ),
            _buildInfoRow(
              'Available Stock',
              '${_availableQuantity.toStringAsFixed(0)} $_unitName',
              textColor: _availableQuantity <= 0 ? theme.colorScheme.error : theme.colorScheme.primary,
              isBold: true,
            ),
            const Divider(height: 32),
            Text(
              'Report Description:',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                _description.isNotEmpty ? _description : 'No description provided.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: _description.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(ThemeData theme, InputDecoration inputDecoration) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Transaction details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'Transfer Quantity',
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: inputDecoration.copyWith(
                  hintText: 'Enter quantity to stock out',
                  suffixText: _unitName,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = double.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Quantity must be greater than zero';
                  }
                  if (qty > _availableQuantity) {
                    return 'Quantity exceeds available stock ($_availableQuantity)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'Transfer Reason',
              child: DropdownButtonFormField<String>(
                value: _reasonController.text.isNotEmpty ? _reasonController.text : null,
                decoration: inputDecoration.copyWith(
                  hintText: 'Select transfer reason',
                ),
                dropdownColor: theme.colorScheme.surface,
                items: ['EXPIRED', 'DAMAGED', 'LOST', 'REPLENISHMENT', 'LOW_STOCK', 'OTHER'].map((val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _reasonController.text = val;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Reason is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'Message / Notes',
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: inputDecoration.copyWith(
                  hintText: 'Add additional comments for the inventory transaction log',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'Status',
              child: TextFormField(
                initialValue: _selectedStatus,
                readOnly: true,
                decoration: inputDecoration.copyWith(
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => context.pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _confirmStockOut,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Stock-Out'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? textColor, Widget? customBadge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          customBadge ??
              Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
