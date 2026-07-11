import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';

class StockInFormScreen extends ConsumerStatefulWidget {
  final int purchaseRequestNumber;

  const StockInFormScreen({
    super.key,
    required this.purchaseRequestNumber,
  });

  @override
  ConsumerState<StockInFormScreen> createState() => _StockInFormScreenState();
}

class _StockInFormScreenState extends ConsumerState<StockInFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isSaving = false;

  String _supplierName = '';
  int? _supplierNumber;
  DateTime? _requestDate;
  String _prStatus = '';

  final List<StockInItemState> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Record Stock-In',
            actions: [],
            breadcrumbs: ['Inventory', 'Transactions', 'Record Stock-In'],
          );
    });
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchStockInFormData(widget.purchaseRequestNumber);
      setState(() {
        _supplierName = data['supplierName'] ?? 'Unknown';
        _supplierNumber = data['supplierNumber'];
        if (data['createdDate'] != null) {
          _requestDate = DateTime.parse(data['createdDate']);
        }
        _prStatus = data['status'] ?? 'Unknown';

        final rawItems = data['items'] as List<dynamic>? ?? [];
        _items.clear();
        for (var rawItem in rawItems) {
          final itemMap = rawItem as Map<String, dynamic>;
          final item = StockInItemState(
            productNumber: itemMap['productNumber'],
            productName: itemMap['productName'] ?? 'Unknown',
            sku: itemMap['sku'] ?? 'N/A',
            requestedQuantity: (itemMap['requestedQuantity'] as num?)?.toDouble() ?? 0.0,
            importPrice: (itemMap['importPrice'] as num?)?.toDouble() ?? 0.0,
            unitName: itemMap['unitName'] ?? 'Unit',
          );
          // Set default dates
          item.manufacturingDate = DateTime.now().subtract(const Duration(days: 5));
          item.expiryDate = DateTime.now().add(const Duration(days: 180));
          _items.add(item);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchase request details: $e'),
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

  Future<void> _checkDiscrepancies() async {
    final Map<int, double> deliveredMap = {};
    for (var item in _items) {
      final qty = double.tryParse(item.deliveredQtyController.text) ?? 0.0;
      deliveredMap[item.productNumber] = qty;
    }

    try {
      final result = await _apiService.compareStockInQuantities(
        widget.purchaseRequestNumber,
        deliveredMap,
      );

      final differences = result['differences'] as Map<String, dynamic>? ?? {};
      final hasDiscrepancy = result['hasDiscrepancy'] as bool? ?? false;

      setState(() {
        for (var item in _items) {
          final diffKey = item.productNumber.toString();
          if (differences.containsKey(diffKey)) {
            final diff = (differences[diffKey] as num).toDouble();
            item.hasDiscrepancy = diff != 0.0;
            item.discrepancyDiff = diff;
            item.status = item.hasDiscrepancy ? 'Partial' : 'Completed';
          }
        }
      });

      if (!mounted) return;

      if (hasDiscrepancy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity discrepancy detected! Please report delivery issues.'),
            backgroundColor: Colors.orange,
          ),
        );

        // Find the first discrepancy that hasn't been reported yet and show the popup
        final itemToReport = _items.firstWhere(
          (item) => item.hasDiscrepancy && item.reportReasonController.text.isEmpty,
          orElse: () => _items.firstWhere((item) => item.hasDiscrepancy),
        );
        _showReportDeliveryIssuePopup(itemToReport);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All delivered quantities match requested quantities.'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to compare quantities: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showReportDeliveryIssuePopup(StockInItemState item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ReportDeliveryIssueDialog(
          purchaseRequestNumber: widget.purchaseRequestNumber,
          item: item,
          onReportSaved: (description, issueType) {
            setState(() {
              item.reportReasonController.text = description;
              item.selectedIssueType = issueType;
            });
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isMfgDate, StockInItemState item) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMfgDate
          ? (item.manufacturingDate ?? DateTime.now())
          : (item.expiryDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMfgDate) {
          item.manufacturingDate = picked;
        } else {
          item.expiryDate = picked;
        }
      });
    }
  }

  Future<void> _confirmStockIn() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct invalid stock-in information.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Check for unreported discrepancies
    List<StockInItemState> unreportedDiscrepancies = [];
    for (var item in _items) {
      final qty = double.tryParse(item.deliveredQtyController.text) ?? 0.0;
      if (qty != item.requestedQuantity && item.reportReasonController.text.trim().isEmpty) {
        unreportedDiscrepancies.add(item);
      }
    }

    if (unreportedDiscrepancies.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please report delivery issue for ${unreportedDiscrepancies.first.productName} first.'),
          backgroundColor: Colors.orange,
        ),
      );
      _showReportDeliveryIssuePopup(unreportedDiscrepancies.first);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'purchaseRequestNumber': widget.purchaseRequestNumber,
        'supplierNumber': _supplierNumber,
        'createdBy': 'e3b3ec4a-da0b-40f5-9747-29361993892b', // Default Stock Controller UUID from database
        'items': _items.map((item) {
          final qty = double.tryParse(item.deliveredQtyController.text) ?? 0.0;
          return {
            'productNumber': item.productNumber,
            'deliveredQuantity': qty,
            'importPrice': item.importPrice,
            'manufacturingDate': item.manufacturingDate != null
                ? DateFormat('yyyy-MM-dd').format(item.manufacturingDate!)
                : null,
            'expiryDate': item.expiryDate != null
                ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
                : null,
            'notes': item.notesController.text.trim(),
          };
        }).toList(),
      };

      final success = await _apiService.submitStockIn(payload);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock-In has been recorded successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save stock-in: $e'),
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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

              // Single Beautiful Card containing everything, matching ProductFormScreen style
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Stock-In Form Details',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // PR Info block grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;
                            return Wrap(
                              spacing: 24,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: isWide ? 200 : double.infinity,
                                  child: _buildInfoColumn(
                                    context: context,
                                    label: 'Purchase Request ID',
                                    value: '#PR-${widget.purchaseRequestNumber}',
                                    isHighlight: true,
                                  ),
                                ),
                                SizedBox(
                                  width: isWide ? 220 : double.infinity,
                                  child: _buildInfoColumn(
                                    context: context,
                                    label: 'Supplier',
                                    value: _supplierName,
                                  ),
                                ),
                                SizedBox(
                                  width: isWide ? 180 : double.infinity,
                                  child: _buildInfoColumn(
                                    context: context,
                                    label: 'Request Date',
                                    value: _requestDate != null
                                        ? DateFormat('yyyy-MM-dd').format(_requestDate!)
                                        : '-',
                                  ),
                                ),
                                _buildStatusBadge(context, _prStatus),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Items list title & verify button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Request Items & Delivered Quantities',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _checkDiscrepancies,
                            icon: const Icon(Icons.compare_arrows),
                            label: const Text('Verify Quantities'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Table Area
                      Form(
                        key: _formKey,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                theme.colorScheme.surfaceContainerLow,
                              ),
                              headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              columns: const [
                                DataColumn(label: Text('Product')),
                                DataColumn(label: Text('Req. Qty'), numeric: true),
                                DataColumn(label: Text('Rec. Qty')),
                                DataColumn(label: Text('Import Price')),
                                DataColumn(label: Text('Mfg. Date')),
                                DataColumn(label: Text('Exp. Date')),
                                DataColumn(label: Text('Notes')),
                                DataColumn(label: Text('Report Reason')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: _items.map((item) {
                                final numberInputDecoration = customInputDecoration.copyWith(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'SKU: ${item.sku}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontFamily: 'Courier Prime',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(
                                          item.requestedQuantity.toStringAsFixed(0),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          controller: item.deliveredQtyController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: numberInputDecoration.copyWith(
                                            errorStyle: const TextStyle(height: 0),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: item.hasDiscrepancy ? theme.colorScheme.error : theme.colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: item.hasDiscrepancy ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
                                              ),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            final qty = double.tryParse(val) ?? 0.0;
                                            setState(() {
                                              item.hasDiscrepancy = qty != item.requestedQuantity;
                                              item.status = item.hasDiscrepancy ? 'Partial' : 'Completed';
                                            });
                                          },
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return '';
                                            final qty = double.tryParse(val);
                                            if (qty == null || qty < 0) return '';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '\$${item.importPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontFamily: 'Courier Prime'),
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _selectDate(context, true, item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.colorScheme.outlineVariant),
                                          ),
                                          child: Text(
                                            item.manufacturingDate != null
                                                ? DateFormat('yyyy-MM-dd').format(item.manufacturingDate!)
                                                : 'Select Date',
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      InkWell(
                                        onTap: () => _selectDate(context, false, item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.colorScheme.outlineVariant),
                                          ),
                                          child: Text(
                                            item.expiryDate != null
                                                ? DateFormat('yyyy-MM-dd').format(item.expiryDate!)
                                                : 'Select Date',
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: TextFormField(
                                          controller: item.notesController,
                                          decoration: customInputDecoration.copyWith(
                                            hintText: 'Add notes...',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: TextFormField(
                                          controller: item.reportReasonController,
                                          readOnly: true,
                                          decoration: customInputDecoration.copyWith(
                                            hintText: item.hasDiscrepancy ? 'Report reason...' : '',
                                            hintStyle: TextStyle(
                                              color: item.hasDiscrepancy ? theme.colorScheme.error.withValues(alpha: 0.7) : null,
                                            ),
                                            errorStyle: const TextStyle(height: 0),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onTap: item.hasDiscrepancy
                                              ? () => _showReportDeliveryIssuePopup(item)
                                              : null,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.status == 'Completed'
                                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                              : theme.colorScheme.secondary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: item.status == 'Completed'
                                                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                                : theme.colorScheme.secondary.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Text(
                                          item.status.toUpperCase(),
                                          style: TextStyle(
                                            color: item.status == 'Completed'
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.secondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons Row at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => context.pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _confirmStockIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Confirm Stock-In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final isApproved = status.toUpperCase() == 'APPROVED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isApproved
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isApproved ? theme.colorScheme.primary : theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: isApproved ? theme.colorScheme.primary : theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StockInItemState {
  final int productNumber;
  final String productName;
  final String sku;
  final double requestedQuantity;
  final double importPrice;
  final String unitName;

  final TextEditingController deliveredQtyController;
  final TextEditingController notesController;
  final TextEditingController reportReasonController;
  DateTime? manufacturingDate;
  DateTime? expiryDate;
  bool hasDiscrepancy = false;
  double discrepancyDiff = 0.0;
  String status = 'Completed';
  String? selectedIssueType;

  StockInItemState({
    required this.productNumber,
    required this.productName,
    required this.sku,
    required this.requestedQuantity,
    required this.importPrice,
    required this.unitName,
  })  : deliveredQtyController = TextEditingController(text: requestedQuantity.toStringAsFixed(0)),
        notesController = TextEditingController(text: 'No damage'),
        reportReasonController = TextEditingController();
}

class ReportDeliveryIssueDialog extends StatefulWidget {
  final int purchaseRequestNumber;
  final StockInItemState item;
  final Function(String description, String issueType) onReportSaved;

  const ReportDeliveryIssueDialog({
    super.key,
    required this.purchaseRequestNumber,
    required this.item,
    required this.onReportSaved,
  });

  @override
  State<ReportDeliveryIssueDialog> createState() => _ReportDeliveryIssueDialogState();
}

class _ReportDeliveryIssueDialogState extends State<ReportDeliveryIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isSaving = false;
  String? _selectedIssueType = 'SHORTAGE';
  final _descriptionController = TextEditingController();

  final List<String> _issueTypes = ['SHORTAGE', 'OVER_DELIVERY', 'DAMAGED', 'OTHER'];

  @override
  void initState() {
    super.initState();
    // Default description
    final diff = widget.item.requestedQuantity - (double.tryParse(widget.item.deliveredQtyController.text) ?? 0.0);
    _descriptionController.text = 'Discrepancy of ${diff.abs().toStringAsFixed(0)} units for product ${widget.item.productName}.';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveIssue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final diff = widget.item.requestedQuantity - (double.tryParse(widget.item.deliveredQtyController.text) ?? 0.0);
      final success = await _apiService.saveDeliveryIssue(
        purchaseRequestNumber: widget.purchaseRequestNumber,
        productNumber: widget.item.productNumber,
        issueType: _selectedIssueType!,
        quantity: diff.abs(),
        description: _descriptionController.text.trim(),
      );

      if (success) {
        widget.onReportSaved(_descriptionController.text.trim(), _selectedIssueType!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery issue has been reported successfully.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Server returned failed status.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery issue cannot be saved. $e'),
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

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = widget.item.requestedQuantity - (double.tryParse(widget.item.deliveredQtyController.text) ?? 0.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.report_problem_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          const Text('Report Delivery Issue'),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product: ${widget.item.productName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Requested: ${widget.item.requestedQuantity.toStringAsFixed(0)}'),
                          Text(
                            'Delivered: ${widget.item.deliveredQtyController.text}',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Difference: ${diff.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: diff > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Issue Type Dropdown
                _buildLabel('Issue Type *', theme),
                DropdownButtonFormField<String>(
                  value: _selectedIssueType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  items: _issueTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedIssueType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Description
                _buildLabel('Description *', theme),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    hintText: 'Enter details of the discrepancy...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Description is required';
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _isSaving ? null : _saveIssue,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Report'),
        ),
      ],
    );
  }
}
