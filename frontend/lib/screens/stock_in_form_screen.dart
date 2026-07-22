import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';

class StockInFormScreen extends ConsumerStatefulWidget {
  final int purchaseRequestNumber;
  final int? supplierNumber;

  const StockInFormScreen({
    super.key,
    required this.purchaseRequestNumber,
    this.supplierNumber,
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

  @override
  void dispose() {
    for (var item in _items) {
      item.deliveredQtyController.dispose();
      item.notesController.dispose();
      item.reportReasonController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchStockInFormData(widget.purchaseRequestNumber, widget.supplierNumber);
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
        widget.supplierNumber,
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

    await _checkDiscrepancies();
    if (!mounted) return;

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
        'createdBy': Supabase.instance.client.auth.currentUser?.id ?? ApiService.mockUserUuid, // Default Stock Controller UUID from database
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

              // Section 1: PURCHASE REQUEST INFORMATION header
              Row(
                children: [
                  Icon(Icons.info_outline, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'PURCHASE REQUEST INFORMATION',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // PR Info Card
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
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      final items = [
                        _buildInfoColumn(context, 'Purchase Request ID', '#PR-${widget.purchaseRequestNumber}', isHighlight: true),
                        _buildInfoColumn(context, 'Supplier', _supplierName.isNotEmpty ? _supplierName : 'Supplier'),
                        _buildInfoColumn(
                          context,
                          'Request Date',
                          _requestDate != null ? DateFormat('yyyy-MM-dd').format(_requestDate!) : '-',
                        ),
                        _buildPRStatusBadge(context, _prStatus.isNotEmpty ? _prStatus : 'Approved'),
                      ];

                      if (isWide) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: items,
                        );
                      } else {
                        return Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: items,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Section 2: REQUEST ITEMS TABLE header
              Row(
                children: [
                  Icon(Icons.list_alt_rounded, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'REQUEST ITEMS TABLE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Table Form Card
              Card(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerLow,
                      ),
                      headingRowHeight: 56,
                      dataRowMinHeight: 64,
                      dataRowMaxHeight: 64,
                      horizontalMargin: 20,
                      columnSpacing: 20,
                      headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Req. Qty'), numeric: true),
                        DataColumn(label: Text('Rec. Qty')),
                        DataColumn(label: Text('Purchase Price')),
                        DataColumn(label: Text('Mfg. Date')),
                        DataColumn(label: Text('Exp. Date')),
                        DataColumn(label: Text('Notes')),
                        DataColumn(label: Text('Report Reason')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _items.map((item) {
                        final cellInputDecoration = customInputDecoration.copyWith(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        );
                        final cellBoxDecoration = BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Text(
                                  item.requestedQuantity.toStringAsFixed(0),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 75,
                                height: 40,
                                child: TextFormField(
                                  controller: item.deliveredQtyController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: cellInputDecoration.copyWith(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    final qty = double.tryParse(val) ?? 0.0;
                                    setState(() {
                                      item.hasDiscrepancy = qty != item.requestedQuantity;
                                      item.status = item.hasDiscrepancy ? 'Partially Received' : 'Completed';
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
                              SizedBox(
                                width: 125,
                                height: 40,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: cellBoxDecoration,
                                  child: Text(
                                    NumberFormat.currency(
                                      locale: 'vi_VN',
                                      symbol: '₫',
                                      decimalDigits: 0,
                                    ).format(item.importPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                height: 40,
                                child: InkWell(
                                  onTap: () => _selectDate(context, true, item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: cellBoxDecoration,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.manufacturingDate != null
                                              ? DateFormat('MM/dd/yyyy').format(item.manufacturingDate!)
                                              : 'MM/DD/YYYY',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                height: 40,
                                child: InkWell(
                                  onTap: () => _selectDate(context, false, item),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: cellBoxDecoration,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.expiryDate != null
                                              ? DateFormat('MM/dd/yyyy').format(item.expiryDate!)
                                              : 'MM/DD/YYYY',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 110,
                                height: 40,
                                child: TextFormField(
                                  controller: item.notesController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: cellInputDecoration.copyWith(
                                    hintText: 'No',
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 110,
                                height: 40,
                                child: TextFormField(
                                  controller: item.reportReasonController,
                                  readOnly: true,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: cellInputDecoration.copyWith(
                                    hintText: item.hasDiscrepancy ? '[Report]' : '[Reason]',
                                  ),
                                  onTap: item.hasDiscrepancy
                                      ? () => _showReportDeliveryIssuePopup(item)
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              _buildItemStatusBadge(theme, item.status),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Section 3: Bottom Callout & Action Buttons Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  Widget calloutBox = Container(
                    constraints: const BoxConstraints(maxWidth: 440),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '"This screen is used to confirm actual received inventory based on an approved purchase request."',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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
                        onPressed: _isSaving ? null : _confirmStockIn,
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
                                'Confirm Stock-In',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        calloutBox,
                        actionButtons,
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        calloutBox,
                        const SizedBox(height: 24),
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

  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPRStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final isApproved = status.toUpperCase() == 'APPROVED';
    final color = isApproved ? AppTheme.primaryColor : AppTheme.errorColor;
    final bgColor = isApproved
        ? AppTheme.primaryColor.withValues(alpha: 0.1)
        : AppTheme.errorColor.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemStatusBadge(ThemeData theme, String status) {
    final isCompleted = status == 'Completed';
    final color = isCompleted ? AppTheme.primaryColor : AppTheme.errorColor;
    final bgColor = isCompleted
        ? AppTheme.primaryColor.withValues(alpha: 0.1)
        : AppTheme.errorColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        isCompleted ? 'Completed' : 'Partially Received',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
                  initialValue: _selectedIssueType,
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
