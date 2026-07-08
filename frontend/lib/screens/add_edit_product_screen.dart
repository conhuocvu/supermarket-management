import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inventory_product.dart';
import '../providers/dashboard_provider.dart';
import '../providers/inventory_products_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;
  final InventoryProduct? product;

  const AddEditProductScreen({
    super.key,
    this.productId,
    this.product,
  });

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _reorderController = TextEditingController();
  final _expiryController = TextEditingController(text: '30');
  final _initialQtyController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  int? _selectedCategoryNumber;
  int? _selectedUnitNumber;
  String _status = 'ACTIVE';
  String _imageUrl = '';
  
  bool _isUploadingImage = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isEditMode => widget.productId != null && widget.productId! > 0;

  @override
  void initState() {
    super.initState();
    if (isEditMode && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.productName;
      _barcodeController.text = p.barcode;
      _priceController.text = p.sellingPrice.toString();
      _reorderController.text = p.reorderLevel.toString();
      _expiryController.text = p.expiryWarningDays.toString();
      _descriptionController.text = p.description;
      _status = p.status;
      _imageUrl = p.imageUrl;
      // We will match the category and unit names to ids when they load
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
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _errorMessage = null;
      _isUploadingImage = true;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final apiService = ref.read(apiServiceProvider);
        final publicUrl = await apiService.uploadProductImage(pickedFile);
        
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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      'productName': _nameController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'categoryNumber': _selectedCategoryNumber,
      'inventoryUnitNumber': _selectedUnitNumber,
      'sellingPrice': double.parse(_priceController.text),
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
        await ref
            .read(inventoryProductsProvider.notifier)
            .addProduct(payload);
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
        context.go('/products');
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

    // Update shell layouts title
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: isEditMode ? 'Edit Product' : 'Add New Product',
            actions: [],
          );
    });

    // Match selected category and unit for edit mode
    categoriesState.whenData((categories) {
      if (isEditMode && widget.product != null && _selectedCategoryNumber == null) {
        final matches = categories.where((c) => c.categoryName == widget.product!.categoryName);
        if (matches.isNotEmpty) {
          setState(() {
            _selectedCategoryNumber = matches.first.categoryNumber;
          });
        }
      }
    });

    unitsState.whenData((units) {
      if (isEditMode && widget.product != null && _selectedUnitNumber == null) {
        final matches = units.where((u) => u['unitName'] == widget.product!.unitName);
        if (matches.isNotEmpty) {
          setState(() {
            _selectedUnitNumber = matches.first['unitNumber'] as int?;
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
        borderSide: BorderSide.none,
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header back button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                      onPressed: () => context.go('/products'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEditMode ? 'Edit Product Details' : 'Register New Product',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                      border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Grid layout for fields and image
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: Image upload
                        Expanded(
                          flex: isWide ? 1 : 2,
                          child: _buildImageSelector(theme),
                        ),
                        if (isWide) const SizedBox(width: 24),
                        // Right side: Form inputs
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isWide) const SizedBox(height: 24),
                              _buildFormInputs(theme, categoriesState, unitsState, inputDecorationTheme),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Action buttons at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => context.go('/products'),
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
                          : Text(isEditMode ? 'Update Product' : 'Add Product'),
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

  Widget _buildImageSelector(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1,
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
                      Icon(Icons.broken_image_outlined, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      const Text('Failed to load image link'),
                    ],
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 64,
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
                      'PNG, JPG up to 5MB',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInputs(
    ThemeData theme,
    AsyncValue<List<dynamic>> categoriesState,
    AsyncValue<List<dynamic>> unitsState,
    InputDecoration inputDecorationTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name
        _buildLabel('Product Name *', theme),
        TextFormField(
          controller: _nameController,
          decoration: inputDecorationTheme.copyWith(hintText: 'Enter product name'),
          validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
        ),
        const SizedBox(height: 20),

        // Barcode & Status Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Barcode *', theme),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: inputDecorationTheme.copyWith(hintText: 'Enter product barcode'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Barcode is required' : null,
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
                    value: _status,
                    decoration: inputDecorationTheme,
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

        // Category & Unit Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Category *', theme),
                  categoriesState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Error loading categories'),
                    data: (categories) => DropdownButtonFormField<int?>(
                      value: _selectedCategoryNumber,
                      decoration: inputDecorationTheme.copyWith(hintText: 'Select category'),
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
            // Unit Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Unit *', theme),
                  unitsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Error loading units'),
                    data: (units) => DropdownButtonFormField<int?>(
                      value: _selectedUnitNumber,
                      decoration: inputDecorationTheme.copyWith(hintText: 'Select unit'),
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

        // Selling Price & Reorder Level Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Selling Price (VND) *', theme),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: inputDecorationTheme.copyWith(hintText: 'e.g. 15000'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Price is required';
                      final numVal = double.tryParse(val);
                      if (numVal == null || numVal <= 0) return 'Price must be greater than 0';
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
                    decoration: inputDecorationTheme.copyWith(hintText: 'e.g. 10'),
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

        // Expiry Warning & Initial Stock (if Add mode) Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Expiry Warning Days *', theme),
                  TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: inputDecorationTheme.copyWith(hintText: 'e.g. 30'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Number of days is required';
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
                        ? TextEditingController(text: widget.product?.stock.toString() ?? '0') 
                        : _initialQtyController,
                    enabled: !isEditMode, // Locked in Edit mode, stock changes must go through transactions
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: inputDecorationTheme,
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
        _buildLabel('Product Description', theme),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: inputDecorationTheme.copyWith(hintText: 'Enter product description...'),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
