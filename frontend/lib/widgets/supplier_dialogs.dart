import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier.dart';
import '../models/inventory_product.dart';
import '../models/supplier_product.dart';
import '../providers/supplier_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

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

// ─────────────────────────────────────────────────────────────────────────────
// Add Supplier Dialog
// ─────────────────────────────────────────────────────────────────────────────

class AddSupplierDialog extends ConsumerStatefulWidget {
  const AddSupplierDialog({super.key});

  @override
  ConsumerState<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'ACTIVE';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'supplierName': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'status': _status,
      'contactPerson': _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    try {
      await ref
          .read(supplierListProvider.notifier)
          .createSupplier(data);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Supplier',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  _errorBanner(context, _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(context, 'Supplier Name *', Icons.business),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Supplier name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactPersonController,
                  decoration: _fieldDecoration(context, 'Contact Person', Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: _fieldDecoration(context, 'Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: _fieldDecoration(context, 'Email Address', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Invalid email address format.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: _fieldDecoration(context, 'Address', Icons.location_on_outlined),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: _fieldDecoration(context, 'Category', Icons.category_outlined),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _fieldDecoration(context, 'Status', Icons.check_circle_outline),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: _fieldDecoration(context, 'Notes', Icons.notes_outlined),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Supplier'),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Supplier Dialog
// ─────────────────────────────────────────────────────────────────────────────

class EditSupplierDialog extends ConsumerStatefulWidget {
  final Supplier supplier;

  const EditSupplierDialog({super.key, required this.supplier});

  @override
  ConsumerState<EditSupplierDialog> createState() => _EditSupplierDialogState();
}

class _EditSupplierDialogState extends ConsumerState<EditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _addressController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier.supplierName);
    _phoneController = TextEditingController(text: widget.supplier.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier.email ?? '');
    _contactPersonController = TextEditingController(text: widget.supplier.contactPerson ?? '');
    _addressController = TextEditingController(text: widget.supplier.address ?? '');
    _categoryController = TextEditingController(text: widget.supplier.category ?? '');
    _notesController = TextEditingController(text: widget.supplier.notes ?? '');
    _status = widget.supplier.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'supplierName': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'status': _status,
      'contactPerson': _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    final success = await ref
        .read(supplierListProvider.notifier)
        .updateSupplier(widget.supplier.supplierNumber!, data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final errorState = ref.read(supplierListProvider).error;
      setState(() => _errorMessage = errorState ?? 'An error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Supplier',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  _errorBanner(context, _errorMessage!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: _fieldDecoration(context, 'Supplier Name *', Icons.business),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Supplier name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactPersonController,
                  decoration: _fieldDecoration(context, 'Contact Person', Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: _fieldDecoration(context, 'Phone Number', Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: _fieldDecoration(context, 'Email Address', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Invalid email address format.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: _fieldDecoration(context, 'Address', Icons.location_on_outlined),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: _fieldDecoration(context, 'Category', Icons.category_outlined),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: _fieldDecoration(context, 'Status', Icons.check_circle_outline),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: _fieldDecoration(context, 'Notes', Icons.notes_outlined),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle Supplier Status Dialog
// ─────────────────────────────────────────────────────────────────────────────

class ToggleSupplierStatusDialog extends ConsumerWidget {
  final Supplier supplier;

  const ToggleSupplierStatusDialog({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDeactivating = supplier.status == 'ACTIVE';
    final actionText = isDeactivating ? 'Deactivate' : 'Activate';

    return AlertDialog(
      title: Text('$actionText Supplier'),
      content: Text(
        'Are you sure you want to $actionText ${supplier.supplierName}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDeactivating ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          onPressed: () async {
            final newStatus = isDeactivating ? 'INACTIVE' : 'ACTIVE';
            final success = await ref
                .read(supplierListProvider.notifier)
                .updateSupplierStatus(supplier.supplierNumber!, newStatus);
            if (success && context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(actionText),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UC-SM-03: Assign Products Dialog
// ─────────────────────────────────────────────────────────────────────────────

class AssignSupplierProductsDialog extends StatefulWidget {
  final int supplierNumber;
  final List<SupplierProduct> currentlyAssigned;

  const AssignSupplierProductsDialog({
    super.key,
    required this.supplierNumber,
    required this.currentlyAssigned,
  });

  @override
  State<AssignSupplierProductsDialog> createState() =>
      _AssignSupplierProductsDialogState();
}

class _AssignSupplierProductsDialogState
    extends State<AssignSupplierProductsDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<InventoryProduct> _allProducts = [];
  late Set<int> _selectedProductNumbers;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProductNumbers =
        widget.currentlyAssigned.map((p) => p.productNumber).toSet();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final result = await _apiService.fetchInventoryProducts(size: 200);
      final list = result['items'] as List<InventoryProduct>? ?? [];
      setState(() {
        _allProducts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<InventoryProduct> get _filteredProducts {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _allProducts;
    return _allProducts.where((p) {
      return p.productName.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          (p.categoryName.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Build assignments. For newly assigned products, set importPrice = 0 or keep null/existing
      final List<Map<String, dynamic>> assignments = [];
      for (final id in _selectedProductNumbers) {
        // If it was already assigned, try to keep the old price/moq
        final existingMatch = widget.currentlyAssigned.firstWhere(
          (p) => p.productNumber == id,
          orElse: () => SupplierProduct(
            productNumber: id,
            productName: '',
            sellingPrice: 0.0,
            status: 'ACTIVE',
          ),
        );
        assignments.add({
          'productNumber': id,
          'importPrice': existingMatch.importPrice,
          'minimumOrderQuantity': existingMatch.minimumOrderQuantity,
        });
      }

      await _apiService.assignSupplierProducts(
          widget.supplierNumber, assignments);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredProducts;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Assign Products',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select the products supplied by this supplier.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name, barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _errorBanner(context, _errorMessage!)
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No products found.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, idx) {
                                final p = filtered[idx];
                                final isSelected =
                                    _selectedProductNumbers.contains(p.productNumber);

                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(
                                    p.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'Category: ${p.categoryName} • Barcode: ${p.barcode}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant),
                                  ),
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedProductNumbers.add(p.productNumber);
                                      } else {
                                        _selectedProductNumbers.remove(p.productNumber);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSaving || _isLoading ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UC-SM-04: Set Import Prices Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _PriceMOQEntry {
  final SupplierProduct product;
  final TextEditingController priceController;
  final TextEditingController moqController;

  _PriceMOQEntry({required this.product})
      : priceController = TextEditingController(
          text: product.importPrice != null
              ? product.importPrice!.toStringAsFixed(0)
              : '',
        ),
        moqController = TextEditingController(
          text: product.minimumOrderQuantity != null
              ? product.minimumOrderQuantity!.toStringAsFixed(0)
              : '',
        );

  void dispose() {
    priceController.dispose();
    moqController.dispose();
  }
}

class UpdateSupplierImportPricesDialog extends StatefulWidget {
  final int supplierNumber;
  final List<SupplierProduct> assignedProducts;

  const UpdateSupplierImportPricesDialog({
    super.key,
    required this.supplierNumber,
    required this.assignedProducts,
  });

  @override
  State<UpdateSupplierImportPricesDialog> createState() =>
      _UpdateSupplierImportPricesDialogState();
}

class _UpdateSupplierImportPricesDialogState
    extends State<UpdateSupplierImportPricesDialog> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  String? _errorMessage;
  late List<_PriceMOQEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.assignedProducts
        .map((p) => _PriceMOQEntry(product: p))
        .toList();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    // Validate inputs
    for (final entry in _entries) {
      final priceText = entry.priceController.text.trim();
      final moqText = entry.moqController.text.trim();

      if (priceText.isNotEmpty) {
        final price = double.tryParse(priceText);
        if (price == null || price < 0) {
          setState(() {
            _errorMessage = 'Invalid import price for ${entry.product.productName}.';
          });
          return;
        }
      }

      if (moqText.isNotEmpty) {
        final moq = double.tryParse(moqText);
        if (moq == null || moq < 0) {
          setState(() {
            _errorMessage = 'Invalid Minimum Order Quantity for ${entry.product.productName}.';
          });
          return;
        }
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> assignments = _entries.map((entry) {
        final priceVal = double.tryParse(entry.priceController.text.trim());
        final moqVal = double.tryParse(entry.moqController.text.trim());

        return {
          'productNumber': entry.product.productNumber,
          'importPrice': priceVal,
          'minimumOrderQuantity': moqVal,
        };
      }).toList();

      await _apiService.updateSupplierImportPrices(
          widget.supplierNumber, assignments);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.price_change_outlined,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Set Import Prices & MOQ',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set the import purchase price and minimum order quantity (MOQ) for each product.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              _errorBanner(context, _errorMessage!),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Text(
                        'No products assigned. Assign products first.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final entry = _entries[idx];
                        final p = entry.product;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Selling Price: ${p.sellingPrice.toStringAsFixed(0)}₫ • Barcode: ${p.barcode ?? "—"}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: entry.priceController,
                                      decoration: InputDecoration(
                                        labelText: 'Import Price (₫)',
                                        prefixIcon: const Icon(
                                            Icons.price_change_outlined,
                                            size: 16),
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: entry.moqController,
                                      decoration: InputDecoration(
                                        labelText: 'Min Order Qty (MOQ)',
                                        prefixIcon: const Icon(
                                            Icons.production_quantity_limits_outlined,
                                            size: 16),
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 12),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSaving || _entries.isEmpty ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

