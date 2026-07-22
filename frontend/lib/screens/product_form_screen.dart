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

/// Custom painter for crossed lines placeholder image box
class CrossBoxPainter extends CustomPainter {
  final Color color;
  CrossBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

      _loadProductSupplierDetails();
    }
  }

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

    final barcodeText = _barcodeController.text.trim();
    final barcode = barcodeText.isNotEmpty
        ? barcodeText
        : 'BAR-${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'productName': _nameController.text.trim(),
      'barcode': barcode,
      'categoryNumber': _selectedCategoryNumber,
      'inventoryUnitNumber': _selectedUnitNumber,
      'supplierNumber': _selectedSupplierNumber,
      'sellingPrice': _priceController.text.trim().isEmpty
          ? 0.0
          : (double.tryParse(_priceController.text.replaceAll('.', '')) ?? 0.0),
      'reorderLevel': double.tryParse(_reorderController.text) ?? 10.0,
      'status': _status,
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageUrl,
      'expiryWarningDays': int.tryParse(_expiryController.text) ?? 30,
    };

    if (!isEditMode) {
      payload['initialQuantity'] =
          double.tryParse(_initialQtyController.text) ?? 0.0;
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
            title: isEditMode ? 'EDIT PRODUCT' : 'ADD PRODUCT',
            actions: [],
            breadcrumbs: [
              'Inventory',
              'Products',
              isEditMode ? 'Edit Product' : 'Create New Product',
            ],
          );
    });

    categoriesState.whenData((categories) {
      if (isEditMode &&
          widget.product != null &&
          _selectedCategoryNumber == null) {
        final matches = categories.where(
          (c) => c.categoryName == widget.product!.categoryName,
        );
        if (matches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategoryNumber == null) {
              setState(() {
                _selectedCategoryNumber = matches.first.categoryNumber;
              });
            }
          });
        }
      }
    });

    unitsState.whenData((units) {
      if (isEditMode &&
          widget.product != null &&
          _selectedUnitNumber == null) {
        final matches = units.where(
          (u) => u['unitName'] == widget.product!.unitName,
        );
        if (matches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedUnitNumber == null) {
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop(result ?? false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          onPressed: () => context.pop(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(
                            alpha: 0.2,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 20),
                    ],

                    // Card containing the wireframe layout
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Product Name & Category
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildProductNameField(theme, inputDecorationTheme),
                                      const SizedBox(height: 20),
                                      _buildCategoryField(theme, categoriesState, inputDecorationTheme),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildProductNameField(theme, inputDecorationTheme)),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildCategoryField(theme, categoriesState, inputDecorationTheme)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Row 2: Unit, Supplier, Shelf Life (Days)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 700;
                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildUnitField(theme, unitsState, inputDecorationTheme),
                                      const SizedBox(height: 20),
                                      _buildSupplierField(theme, suppliersState, inputDecorationTheme),
                                      const SizedBox(height: 20),
                                      _buildShelfLifeField(theme, inputDecorationTheme),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 1, child: _buildUnitField(theme, unitsState, inputDecorationTheme)),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 1, child: _buildSupplierField(theme, suppliersState, inputDecorationTheme)),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 1, child: _buildShelfLifeField(theme, inputDecorationTheme)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Row 3: Description
                            _buildLabel('Description', theme),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: inputDecorationTheme.copyWith(
                                hintText:
                                    '[Provide detailed product description and handling requirements here...]',
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Row 4: Product Reference Image
                            _buildImageSelector(theme),
                            const SizedBox(height: 32),

                            // Divider
                            const Divider(color: Color(0xFFE5E7EB), height: 1),
                            const SizedBox(height: 24),

                            // Row 5: Action Buttons (Cancel & Save Product)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isSaving ? null : () => context.pop(false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    foregroundColor: const Color(0xFF1F2937),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                FilledButton(
                                  onPressed: _isSaving || _isUploadingImage
                                      ? null
                                      : _saveProduct,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          isEditMode ? 'Save Product' : 'Save Product',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductNameField(ThemeData theme, InputDecoration inputDecoration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Product Name', theme),
        TextFormField(
          controller: _nameController,
          decoration: inputDecoration.copyWith(
            hintText: '[Enter Product Name Here]',
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Product name is required'
              : null,
        ),
      ],
    );
  }

  Widget _buildCategoryField(
    ThemeData theme,
    AsyncValue<List<dynamic>> categoriesState,
    InputDecoration inputDecoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Category', theme),
        categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error loading categories'),
          data: (categories) => DropdownButtonFormField<int?>(
            initialValue: _selectedCategoryNumber,
            decoration: inputDecoration.copyWith(
              hintText: '[Select Category]',
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
    );
  }

  Widget _buildUnitField(
    ThemeData theme,
    AsyncValue<List<dynamic>> unitsState,
    InputDecoration inputDecoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Unit', theme),
        unitsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error loading units'),
          data: (units) => DropdownButtonFormField<int?>(
            initialValue: _selectedUnitNumber,
            decoration: inputDecoration.copyWith(
              hintText: '[e.g. kg, box, pc]',
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
    );
  }

  Widget _buildSupplierField(
    ThemeData theme,
    AsyncValue<List<dynamic>> suppliersState,
    InputDecoration inputDecoration,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Supplier', theme),
        suppliersState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Text('Error loading suppliers'),
          data: (suppliers) => DropdownButtonFormField<int?>(
            initialValue: _selectedSupplierNumber,
            decoration: inputDecoration.copyWith(
              hintText: '[Search Supplier]',
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
    );
  }

  Widget _buildShelfLifeField(ThemeData theme, InputDecoration inputDecoration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Shelf Life (Days)', theme),
        TextFormField(
          controller: _expiryController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: inputDecoration.copyWith(hintText: '[00]'),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Shelf life is required';
            final numVal = int.tryParse(val);
            if (numVal == null || numVal < 0) return 'Invalid value';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildImageSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Product Reference Image', theme),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_imageUrl.isNotEmpty)
                    Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      width: 110,
                      height: 110,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                    )
                  else
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: CrossBoxPainter(color: const Color(0xFFD1D5DB)),
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
                      ),
                    ),
                  if (_isUploadingImage)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: _isUploadingImage || _isSaving ? null : _pickAndUploadImage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _imageUrl.isNotEmpty ? 'Change Image' : 'Upload Image',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Max size: 2MB. JPG or PNG only.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
}
