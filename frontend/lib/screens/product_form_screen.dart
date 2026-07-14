import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/inventory_product.dart';
import '../providers/dashboard_provider.dart';
import '../providers/inventory_products_provider.dart';
import '../providers/shell_layout_provider.dart';

/// Formats integers with dots as thousand separators (Vietnamese style: 100.000).
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    // Insert dot every 3 digits from the right
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  final InventoryProduct? product;

  const ProductFormScreen({super.key, this.productId, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _reorderController = TextEditingController();
  final _expiryController = TextEditingController(text: '30');
  final _initialQtyController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  late final TextEditingController _stockDisplayController;

  int? _selectedCategoryNumber;
  int? _selectedUnitNumber;
  int? _selectedSupplierNumber;
  String _status = 'ACTIVE';
  String _imageUrl = '';

  bool _isUploadingImage = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isEditMode => widget.productId != null && widget.productId! > 0;

  @override
  void initState() {
    super.initState();
    _stockDisplayController = TextEditingController(
      text: widget.product?.stock.toString() ?? '0',
    );
    if (isEditMode && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.productName;
      _barcodeController.text = p.barcode;
      _priceController.text = _formatPrice(p.sellingPrice);
      _reorderController.text = p.reorderLevel.toString();
      _expiryController.text = p.expiryWarningDays.toString();
      _descriptionController.text = p.description;
      _status = p.status;
      _imageUrl = p.imageUrl;
      
      // Load supplier mapping
      _loadProductSupplierDetails();
    }
  }

  /// Formats a double to Vietnamese dot-separated integer string (e.g. 100000.0 → "100.000")
  String _formatPrice(double price) {
    final intVal = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < intVal.length; i++) {
      if (i > 0 && (intVal.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intVal[i]);
    }
    return buffer.toString();
  }

  Future<void> _loadProductSupplierDetails() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final details = await apiService.fetchProductDetails(widget.productId!);
      if (mounted) {
        setState(() {
          _selectedSupplierNumber = details.supplierNumber;
        });
      }
    } catch (e) {
      debugPrint('Failed to load product supplier: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _reorderController.dispose();
    _expiryController.dispose();
    _initialQtyController.dispose();
    _descriptionController.dispose();
    _stockDisplayController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _errorMessage = null;
      _isUploadingImage = true;
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final fileSize = result.files.single.size;
        // Check if file is larger than 2MB (2 * 1024 * 1024 bytes)
        if (fileSize > 2 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'File size exceeds the limit (maximum 2MB).';
            _isUploadingImage = false;
          });
          return;
        }

        final xFile = XFile(result.files.single.path!);
        final apiService = ref.read(apiServiceProvider);
        final publicUrl = await apiService.uploadProductImage(xFile);

        setState(() {
          _imageUrl = publicUrl;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Image upload failed: $e'.replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryNumber == null) {
      setState(() => _errorMessage = 'Please select a category.');
      return;
    }
    if (_selectedUnitNumber == null) {
      setState(() => _errorMessage = 'Please select a unit.');
      return;
    }
    if (_selectedSupplierNumber == null) {
      setState(() => _errorMessage = 'Please select a supplier.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'productName': _nameController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'categoryNumber': _selectedCategoryNumber,
      'inventoryUnitNumber': _selectedUnitNumber,
      'supplierNumber': _selectedSupplierNumber,
      'sellingPrice': _priceController.text.trim().isEmpty 
          ? 0.0 
          : double.parse(_priceController.text.replaceAll('.', '')),
      'reorderLevel': double.parse(_reorderController.text),
      'status': _status,
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageUrl,
      'expiryWarningDays': int.parse(_expiryController.text),
    };

    if (!isEditMode) {
      payload['initialQuantity'] = double.parse(_initialQtyController.text);
    }

    try {
      if (isEditMode) {
        await ref
            .read(inventoryProductsProvider.notifier)
            .updateProduct(widget.productId!, payload);
      } else {
        await ref.read(inventoryProductsProvider.notifier).addProduct(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Product updated successfully!'
                  : 'Product created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Save failed: $e'.replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = ref.watch(categoriesListProvider);
    final unitsState = ref.watch(unitsListProvider);
    final suppliersState = ref.watch(suppliersListProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(shellLayoutProvider.notifier)
          .update(
            title: isEditMode ? 'Edit Product' : 'Add New Product',
            actions: [],
            breadcrumbs: [
              'Inventory',
              'Products',
              isEditMode ? 'Edit Product' : 'Add Product',
            ],
          );
    });

    // Match selected category and unit for edit mode
    categoriesState.whenData((categories) {
      if (isEditMode &&
          widget.product != null &&
          _selectedCategoryNumber == null) {
        final matches = categories.where(
          (c) => c.categoryName == widget.product!.categoryName,
        );
        if (matches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCategoryNumber = matches.first.categoryNumber;
              });
            }
          });
        }
      }
    });

    unitsState.whenData((units) {
      if (isEditMode && widget.product != null && _selectedUnitNumber == null) {
        final matches = units.where(
          (u) => u['unitName'] == widget.product!.unitName,
        );
        if (matches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedUnitNumber = matches.first['unitNumber'] as int?;
              });
            }
          });
        }
      }
    });

    final inputDecorationTheme = InputDecoration(
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

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(result ?? false);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Card containing the entire form
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
                          // Top section: Image Selector and basic fields
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 800;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: isWide ? 1 : 2,
                                    child: _buildImageSelector(theme),
                                  ),
                                  if (isWide) const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isWide) const SizedBox(height: 24),
                                        _buildFormFields(
                                          theme,
                                          categoriesState,
                                          unitsState,
                                          suppliersState,
                                          inputDecorationTheme,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => context.pop(false),
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
                        onPressed: _isSaving || _isUploadingImage ? null : _saveProduct,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditMode ? 'Update Product' : 'Save Product',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Product Reference Image', theme),
        const SizedBox(height: 8),
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isUploadingImage || _isSaving ? null : _pickAndUploadImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_imageUrl.isNotEmpty)
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        const Text('Failed to load image'),
                      ],
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload Image',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Max size: 2MB. JPG or PNG only.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                if (_isUploadingImage)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (_imageUrl.isNotEmpty && !_isUploadingImage && !_isSaving)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Change',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(
    ThemeData theme,
    AsyncValue<List<dynamic>> categoriesState,
    AsyncValue<List<dynamic>> unitsState,
    AsyncValue<List<dynamic>> suppliersState,
    InputDecoration inputDecoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name & Barcode
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Product Name *', theme),
                  TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter product name',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Product name is required'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Barcode *', theme),
                  TextFormField(
                    controller: _barcodeController,
                    enabled: !isEditMode, // Product code cannot be modified after creation (BR-I-02)
                    decoration: inputDecoration.copyWith(
                      hintText: 'Enter product barcode',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Barcode is required'
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Category & Unit Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Category *', theme),
                  categoriesState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Error loading categories'),
                    data: (categories) => DropdownButtonFormField<int?>(
                      initialValue: _selectedCategoryNumber,
                      decoration: inputDecoration.copyWith(
                        hintText: 'Select category',
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem<int?>(
                          value: c.categoryNumber,
                          child: Text(c.categoryName),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryNumber = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Unit *', theme),
                  unitsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Error loading units'),
                    data: (units) => DropdownButtonFormField<int?>(
                      initialValue: _selectedUnitNumber,
                      decoration: inputDecoration.copyWith(
                        hintText: 'Select unit',
                      ),
                      items: units.map((u) {
                        return DropdownMenuItem<int?>(
                          value: u['unitNumber'] as int?,
                          child: Text(u['unitName'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedUnitNumber = val),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Supplier & Status Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Supplier *', theme),
                  suppliersState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Error loading suppliers'),
                    data: (suppliers) => DropdownButtonFormField<int?>(
                      initialValue: _selectedSupplierNumber,
                      decoration: inputDecoration.copyWith(
                        hintText: 'Select Supplier',
                      ),
                      items: suppliers.map((s) {
                        return DropdownMenuItem<int?>(
                          value: s['supplierNumber'] as int?,
                          child: Text(s['supplierName'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSupplierNumber = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Status *', theme),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: inputDecoration,
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Selling Price & Reorder Level Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Selling Price (VND)', theme),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsSeparatorFormatter()],
                    decoration: inputDecoration.copyWith(
                      hintText: 'e.g. 100.000',
                      suffixText: 'VND',
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final numVal = double.tryParse(val.replaceAll('.', ''));
                        if (numVal != null && numVal < 0) return 'Price cannot be negative';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Reorder Level *', theme),
                  TextFormField(
                    controller: _reorderController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: inputDecoration.copyWith(
                      hintText: 'e.g. 10',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Reorder level is required';
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal < 0) return 'Value cannot be negative';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Shelf Life (Expiry warning) & Initial / Current Stock Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Shelf Life (Days) *', theme),
                  TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: inputDecoration.copyWith(
                      hintText: 'e.g. 30',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Shelf life is required';
                      final numVal = int.tryParse(val);
                      if (numVal == null || numVal < 0) return 'Invalid value';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(
                    isEditMode ? 'Current Stock (Read-only)' : 'Initial Stock *',
                    theme,
                  ),
                  TextFormField(
                    controller: isEditMode
                        ? _stockDisplayController
                        : _initialQtyController,
                    enabled: !isEditMode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: inputDecoration,
                    validator: (val) {
                      if (!isEditMode) {
                        if (val == null || val.trim().isEmpty) return 'Initial stock is required';
                        final numVal = double.tryParse(val);
                        if (numVal == null || numVal < 0) return 'Value cannot be negative';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Description
        _buildLabel('Description', theme),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: inputDecoration.copyWith(
            hintText: 'Provide detailed product description...',
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
