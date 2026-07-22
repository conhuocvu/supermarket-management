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
  double _reportedQuantity = 0.0;
  String _unitName = '';
  String _location = '';
  String _issueType = '';
  double _availableQuantity = 0.0;
  final String _reportDateStr = '2024-05-20 09:15 AM';

  // Controllers & Form selection
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedStatusUpdate = 'Restocked';

  final List<String> _statusOptions = [
    'Restocked',
    'Partially Restocked',
    'Out of Stock',
    'Purchase Requested',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Process Stock-Out',
            actions: [],
            breadcrumbs: ['Inventory', 'Transactions', 'Process Stock-Out'],
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
        _productName = data['productName'] ?? 'Unknown Product';
        _reportedQuantity = (data['quantity'] as num?)?.toDouble() ?? 0.0;
        _unitName = data['unitName'] ?? 'Pieces';
        _location = data['location'] ?? 'Aisle 4, Shelf B-12';
        _issueType = data['issueType'] ?? '';
        _availableQuantity = (data['availableQuantity'] as num?)?.toDouble() ?? 0.0;

        _quantityController.text = _reportedQuantity.toStringAsFixed(0);
        _reasonController.text = _issueType.isNotEmpty ? _issueType : 'Shelf Replenishment';
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
        'statusUpdate': _selectedStatusUpdate,
        'createdBy': Supabase.instance.client.auth.currentUser?.id ?? ApiService.mockUserUuid,
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final customInputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Back button
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
              const SizedBox(height: 20),

              // Layout Builder for responsive 2-column wireframe layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;

                  Widget leftColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: REPORT INFORMATION
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined, size: 22, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'REPORT INFORMATION',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Report Information Card
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              final isCardWide = cardConstraints.maxWidth > 500;
                              return Column(
                                children: [
                                  _buildGridRow(
                                    context,
                                    isCardWide,
                                    'REPORT ID',
                                    '#REP-${widget.reportNumber}',
                                    'PRODUCT',
                                    _productName,
                                    leftBold: true,
                                    rightBold: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGridRow(
                                    context,
                                    isCardWide,
                                    'SHELF LOCATION',
                                    _location.isNotEmpty ? _location : 'Aisle 4, Shelf B-12',
                                    'REQUESTED QUANTITY',
                                    '${_reportedQuantity.toStringAsFixed(0)} ${_unitName.isNotEmpty ? _unitName : 'Pieces'}',
                                    rightBold: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGridRow(
                                    context,
                                    isCardWide,
                                    'REPORT DATE',
                                    _reportDateStr,
                                    'CURRENT WAREHOUSE STOCK',
                                    '${_availableQuantity.toStringAsFixed(0)} ${_unitName.isNotEmpty ? _unitName : 'Pieces'}',
                                    rightBold: true,
                                    rightHighlight: true,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Section 2: STOCK-OUT DETAILS
                      Row(
                        children: [
                          Icon(Icons.edit_note_outlined, size: 24, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'STOCK-OUT DETAILS',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stock-Out Details Form Card
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: Quantity & Reason/Type
                                LayoutBuilder(
                                  builder: (context, formRowConstraints) {
                                    final isFormRowWide = formRowConstraints.maxWidth > 550;
                                    final qtyField = Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(theme, 'QUANTITY TO TRANSFER (${_unitName.toUpperCase()}) *'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _quantityController,
                                          keyboardType: TextInputType.number,
                                          decoration: customInputDecoration.copyWith(
                                            hintText: 'Enter quantity',
                                          ),
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Quantity is required';
                                            final q = double.tryParse(val);
                                            if (q == null || q <= 0) return 'Quantity must be > 0';
                                            if (q > _availableQuantity) return 'Exceeds warehouse stock';
                                            return null;
                                          },
                                        ),
                                      ],
                                    );

                                    final reasonField = Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel(theme, 'REASON / TYPE *'),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: _reasonController.text.isNotEmpty ? _reasonController.text : 'Shelf Replenishment',
                                          decoration: customInputDecoration,
                                          items: [
                                            'Shelf Replenishment',
                                            'EXPIRED',
                                            'DAMAGED',
                                            'LOST',
                                            'LOW_STOCK',
                                            'OTHER'
                                          ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _reasonController.text = val);
                                            }
                                          },
                                        ),
                                      ],
                                    );

                                    if (isFormRowWide) {
                                      return Row(
                                        children: [
                                          Expanded(child: qtyField),
                                          const SizedBox(width: 20),
                                          Expanded(child: reasonField),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          qtyField,
                                          const SizedBox(height: 16),
                                          reasonField,
                                        ],
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Row 2: Message to Store Staff
                                _buildFieldLabel(theme, 'MESSAGE TO STORE STAFF'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  decoration: customInputDecoration.copyWith(
                                    hintText: '[Optional notes for the store team...]',
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Row 3: Status Update (Radio options)
                                _buildFieldLabel(theme, 'STATUS UPDATE'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: _statusOptions.map((status) {
                                    final isSelected = _selectedStatusUpdate == status;
                                    return InkWell(
                                      onTap: () {
                                        setState(() => _selectedStatusUpdate = status);
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outlineVariant,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? theme.colorScheme.primary
                                                      : theme.colorScheme.outline,
                                                  width: isSelected ? 5 : 1.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  Widget rightSidebar = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // WAREHOUSE STOCK SUMMARY Card
                      Card(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'WAREHOUSE STOCK\nSUMMARY',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              _buildSidebarStockRow(
                                context,
                                'Current Stock:',
                                '${(_availableQuantity + 22).toStringAsFixed(0)} ${_unitName.isNotEmpty ? _unitName : 'Pieces'}',
                              ),
                              const SizedBox(height: 12),
                              _buildSidebarStockRow(
                                context,
                                'Reserved Stock:',
                                '22 ${_unitName.isNotEmpty ? _unitName : 'Pieces'}',
                              ),
                              const SizedBox(height: 12),
                              Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              _buildSidebarStockRow(
                                context,
                                'AVAILABLE STOCK:',
                                '${_availableQuantity.toStringAsFixed(0)} ${_unitName.isNotEmpty ? _unitName : 'Pieces'}',
                                isBold: true,
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Safety tip callout box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '"Ensure warehouse levels remain above safety threshold before confirming large transfers."',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: leftColumn),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: rightSidebar),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        leftColumn,
                        const SizedBox(height: 24),
                        rightSidebar,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 32),

              // Bottom Footer Action Row with Divider
              Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isFooterWide = constraints.maxWidth > 700;

                  Widget noteText = Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Text(
                      'Note: This screen is used to process low-stock shelf reports and transfer inventory from warehouse to store shelves.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );

                  Widget actionButtons = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: _isSaving ? null : _confirmStockOut,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Confirm Stock-Out',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ],
                  );

                  if (isFooterWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        noteText,
                        actionButtons,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        noteText,
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionButtons,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGridRow(
    BuildContext context,
    bool isWide,
    String leftLabel,
    String leftValue,
    String rightLabel,
    String rightValue, {
    bool leftBold = false,
    bool rightBold = false,
    bool rightHighlight = false,
  }) {
    final theme = Theme.of(context);

    Widget leftBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          leftLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          leftValue,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: leftBold ? FontWeight.bold : FontWeight.normal,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    Widget rightBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rightLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rightValue,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: rightBold ? FontWeight.bold : FontWeight.normal,
            color: rightHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: leftBlock),
          const SizedBox(width: 16),
          Expanded(child: rightBlock),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftBlock,
          const SizedBox(height: 12),
          rightBlock,
        ],
      );
    }
  }

  Widget _buildSidebarStockRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
