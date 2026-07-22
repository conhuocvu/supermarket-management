import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/purchase_request.dart';
import '../providers/shell_layout_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/purchase_request_provider.dart';

class PurchaseRequestFormScreen extends ConsumerStatefulWidget {
  const PurchaseRequestFormScreen({super.key});

  @override
  ConsumerState<PurchaseRequestFormScreen> createState() =>
      _PurchaseRequestFormScreenState();
}

class _RequestItemRowState {
  ProductFormData? selectedProduct;
  ProductSupplierInfo? selectedSupplier;
  final TextEditingController quantityController;
  String selectedReason;
  final TextEditingController notesController;

  _RequestItemRowState({
    this.selectedProduct,
    this.selectedSupplier,
    required String quantity,
    this.selectedReason = 'Low Stock',
    required String notes,
  })  : quantityController = TextEditingController(text: quantity),
        notesController = TextEditingController(text: notes);

  void dispose() {
    quantityController.dispose();
    notesController.dispose();
  }
}

class _PurchaseRequestFormScreenState
    extends ConsumerState<PurchaseRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _errorMessage;

  PurchaseRequestFormData? _formData;
  PurchaseRequestDetail? _draftRequest;

  DateTime? _expectedDeliveryDate;
  final List<_RequestItemRowState> _rows = [];

  final List<String> _reasonsList = [
    'Low Stock',
    'Shelf Replenishment',
    'Expired Product Replacement',
    'Manual Request',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Create Purchase Request',
            actions: [],
            breadcrumbs: ['Inventory', 'Purchase Requests', 'Create'],
          );
      _loadData();
    });
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Load form options and active draft concurrently
      final responses = await Future.wait([
        apiService.fetchPurchaseRequestFormData(),
        apiService.fetchOrCreateDraftPurchaseRequest(),
      ]);

      _formData = responses[0] as PurchaseRequestFormData;
      _draftRequest = responses[1] as PurchaseRequestDetail;

      if (_draftRequest != null) {
        _expectedDeliveryDate = _draftRequest!.expectedDeliveryDate;
        
        // Populate existing items from draft
        _rows.clear();
        for (var item in _draftRequest!.items) {
          // Find matching product in form options
          final productOpt = _formData!.products.firstWhere(
            (p) => p.productNumber == item.productNumber,
            orElse: () => ProductFormData(
              productNumber: item.productNumber,
              productName: item.productName,
              barcode: item.sku,
              unitName: item.unitName,
              currentStock: item.currentStock ?? 0.0,
              reorderLevel: item.reorderLevel ?? 0.0,
              suppliers: [],
            ),
          );

          // Find matching supplier in product suppliers
          ProductSupplierInfo? supplierOpt;
          if (productOpt.suppliers.isNotEmpty) {
            supplierOpt = productOpt.suppliers.firstWhere(
              (s) => s.supplierName == item.supplierName,
              orElse: () => productOpt.suppliers.first,
            );
          }

          _rows.add(_RequestItemRowState(
            selectedProduct: productOpt,
            selectedSupplier: supplierOpt,
            quantity: item.requestedQuantity.toStringAsFixed(0),
            selectedReason: item.reason ?? 'Low Stock',
            notes: item.notes ?? '',
          ));
        }
      }

      if (_rows.isEmpty) {
        _addNewRow();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  void _addNewRow() {
    setState(() {
      _rows.add(_RequestItemRowState(
        quantity: '0',
        selectedReason: 'Low Stock',
        notes: '',
      ));
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length > 1) {
        _rows[index].dispose();
        _rows.removeAt(index);
      } else {
        // Clear instead of removing last row
        _rows[0].selectedProduct = null;
        _rows[0].selectedSupplier = null;
        _rows[0].quantityController.text = '0';
        _rows[0].selectedReason = 'Low Stock';
        _rows[0].notesController.text = '';
      }
    });
  }

  double _calculateEstimatedTotal() {
    double total = 0.0;
    for (var row in _rows) {
      if (row.selectedSupplier != null) {
        final qty = double.tryParse(row.quantityController.text) ?? 0.0;
        total += qty * row.selectedSupplier!.importPrice;
      }
    }
    return total;
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  Map<String, dynamic> _buildPayload() {
    final List<Map<String, dynamic>> itemsPayload = [];
    for (var row in _rows) {
      if (row.selectedProduct != null && row.selectedSupplier != null) {
        itemsPayload.add({
          'productNumber': row.selectedProduct!.productNumber,
          'supplierNumber': row.selectedSupplier!.supplierNumber,
          'requestedQuantity': double.tryParse(row.quantityController.text) ?? 0.0,
          'reason': row.selectedReason,
          'notes': row.notesController.text,
        });
      }
    }

    return {
      'expectedDeliveryDate': _expectedDeliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(_expectedDeliveryDate!)
          : null,
      'items': itemsPayload,
    };
  }

  Future<void> _saveDraft() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = _buildPayload();
      _draftRequest = await ref.read(purchaseRequestOperationsProvider.notifier).saveDraft(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft purchase request saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() != true) return;

    // Validate that at least one item is completely filled
    final hasItems = _rows.any((row) => row.selectedProduct != null && row.selectedSupplier != null);
    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one request item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Save draft details first to commit changes
      final payload = _buildPayload();
      final savedDraft = await ref.read(purchaseRequestOperationsProvider.notifier).saveDraft(payload);

      // 2. Submit the purchase request for approval
      final ok = await ref.read(purchaseRequestOperationsProvider.notifier).submitForApproval(savedDraft.purchaseRequestNumber);

      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase request has been created and submitted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate successful creation
        }
      } else {
        throw Exception('Server rejected the submission.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Purchase Request Form cannot be loaded.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(false),
                        child: const Text('Go Back'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _loadData,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                onPressed: () => context.pop(false),
              ),
              const SizedBox(height: 16),

              // Title Header
              Text(
                'Create New Purchase Request',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill out the details below to initiate a procurement workflow.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Form Container
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expected Delivery Date Selector
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPECTED DELIVERY DATE',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _expectedDeliveryDate ??
                                    DateTime.now().add(const Duration(days: 3)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _expectedDeliveryDate = pickedDate;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _expectedDeliveryDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_expectedDeliveryDate!)
                                    : 'Select Expected Delivery Date',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _expectedDeliveryDate == null
                                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Items List Area
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REQUEST ITEMS',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildItemsTable(theme),
                          const SizedBox(height: 24),
                          
                          // Add Row and Estimated Total Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _addNewRow,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ESTIMATED TOTAL: ',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'vi_VN',
                                        symbol: '₫',
                                        decimalDigits: 0,
                                      ).format(_calculateEstimatedTotal()),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions Area
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _saveDraft,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Save Draft'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _submitRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Submit Request'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Instructional Box
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    style: BorderStyle.none, // We can keep it clean without dashes
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Items from different suppliers will be automatically grouped into separate purchase orders after manager approval. You can track individual status in the Purchase Request History.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable(ThemeData theme) {
    final activeProducts = _formData?.products ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerLow,
                ),
                headingRowHeight: 44,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                horizontalMargin: 12,
                columnSpacing: 12,
                headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                columns: const [
                  DataColumn(label: Text('Product Name /\nID')),
                  DataColumn(label: Text('Supplier')),
                  DataColumn(label: Text('Current\nStock')),
                  DataColumn(label: Text('Required\nQty')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('')),
                ],
                rows: List.generate(_rows.length, (index) {
                  final row = _rows[index];
                  return DataRow(
                    cells: [
                      // Product Dropdown
                      DataCell(
                        SizedBox(
                          width: 180,
                          height: 40,
                          child: DropdownButtonFormField<ProductFormData>(
                            isExpanded: true,
                            initialValue: row.selectedProduct,
                            hint: const Text('[Product Name/ID]', style: TextStyle(fontSize: 12)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            items: activeProducts.map((p) {
                              return DropdownMenuItem<ProductFormData>(
                                value: p,
                                child: Text(p.productName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (prod) {
                              setState(() {
                                row.selectedProduct = prod;
                                row.selectedSupplier = null;
                                row.quantityController.text = '0';
                                if (prod != null && prod.suppliers.isNotEmpty) {
                                  row.selectedSupplier = prod.suppliers.first;
                                  row.quantityController.text =
                                      _formatQuantity(prod.suppliers.first.minimumOrderQuantity);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // Supplier Dropdown
                      DataCell(
                        SizedBox(
                          width: 150,
                          height: 40,
                          child: DropdownButtonFormField<ProductSupplierInfo>(
                            isExpanded: true,
                            initialValue: row.selectedSupplier,
                            hint: const Text('[Select]', style: TextStyle(fontSize: 12)),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            items: row.selectedProduct?.suppliers.map((s) {
                              final formattedPrice = NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: '₫',
                                decimalDigits: 0,
                              ).format(s.importPrice);
                              return DropdownMenuItem<ProductSupplierInfo>(
                                value: s,
                                child: Text(
                                  '${s.supplierName} ($formattedPrice)',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList() ?? [],
                            onChanged: (supp) {
                              setState(() {
                                row.selectedSupplier = supp;
                                if (supp != null) {
                                  row.quantityController.text =
                                      _formatQuantity(supp.minimumOrderQuantity);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // Current Stock
                      DataCell(
                        Center(
                          child: Text(
                            row.selectedProduct != null
                                ? _formatQuantity(row.selectedProduct!.currentStock)
                                : '-',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // Required Qty Input
                      DataCell(
                        SizedBox(
                          width: 80,
                          height: 40,
                          child: TextFormField(
                            controller: row.quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      // Reason Dropdown
                      DataCell(
                        SizedBox(
                          width: 140,
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: row.selectedReason,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            items: _reasonsList.map((reason) {
                              return DropdownMenuItem<String>(
                                value: reason,
                                child: Text(reason, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                if (val != null) {
                                  row.selectedReason = val;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // Notes Input
                      DataCell(
                        SizedBox(
                          width: 150,
                          height: 40,
                          child: TextFormField(
                            controller: row.notesController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: '[Notes]',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Delete Trash Icon
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: theme.colorScheme.error,
                          onPressed: () => _removeRow(index),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
