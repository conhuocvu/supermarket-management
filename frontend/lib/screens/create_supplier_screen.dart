import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/inventory_product.dart';
import '../providers/supplier_provider.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UC-SM-02: Create Supplier
// UC-SM-03: Assign Products to Supplier
// UC-SM-04: Set Import Prices
// ─────────────────────────────────────────────────────────────────────────────

// ── Product selection entry (product + assigned import price)
class _ProductEntry {
  final InventoryProduct product;
  bool selected;
  double? importPrice;
  final TextEditingController priceController;

  _ProductEntry({
    required this.product,
    this.importPrice,
  })  : selected = false,
        priceController = TextEditingController(
          text: importPrice != null ? importPrice.toStringAsFixed(0) : '',
        );

  void dispose() => priceController.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class CreateSupplierScreen extends ConsumerStatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  ConsumerState<CreateSupplierScreen> createState() =>
      _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends ConsumerState<CreateSupplierScreen> {
  // Step tracking
  int _currentStep = 0;

  // ── Step 1: Supplier Info ─────────────────────────────────────────────────
  final _infoFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _status = 'ACTIVE';
  bool _isSavingInfo = false;
  String? _infoError;

  // Created supplier number (set after step 1 completes)
  int? _createdSupplierNumber;

  // ── Step 2: Assign Products ──────────────────────────────────────────────
  bool _isLoadingProducts = false;
  String? _productsError;
  List<_ProductEntry> _allProducts = [];
  String _productSearch = '';
  final _productSearchCtrl = TextEditingController();
  bool _isSavingAssignment = false;
  String? _assignError;

  // ── Step 3: Set Import Prices ────────────────────────────────────────────
  bool _isSavingPrices = false;
  String? _pricesError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _contactPersonCtrl.dispose();
    _addressCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    _productSearchCtrl.dispose();
    for (final e in _allProducts) {
      e.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Create Supplier
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _createSupplier() async {
    if (!_infoFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingInfo = true;
      _infoError = null;
    });

    try {
      final notifier = ref.read(supplierListProvider.notifier);
      final newSupplier = await notifier.createSupplier({
        'supplierName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        'email':
            _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
        'contactPerson': _contactPersonCtrl.text.trim().isNotEmpty
            ? _contactPersonCtrl.text.trim()
            : null,
        'address': _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : null,
        'category': _categoryCtrl.text.trim().isNotEmpty
            ? _categoryCtrl.text.trim()
            : null,
        'notes':
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        'status': _status,
      });

      if (mounted) {
        setState(() {
          _createdSupplierNumber = newSupplier;
          _isSavingInfo = false;
          _currentStep = 1;
        });
        // Auto-load products for step 2
        _loadAllProducts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingInfo = false;
          _infoError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Load & Assign Products
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final api = ApiService();
      final result = await api.fetchInventoryProducts(size: 200);
      final products = result['items'] as List<InventoryProduct>? ?? [];

      if (mounted) {
        setState(() {
          _allProducts = products
              .map((p) => _ProductEntry(product: p))
              .toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _productsError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<_ProductEntry> get _filteredProducts {
    final q = _productSearch.toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts.where((e) {
      return e.product.productName.toLowerCase().contains(q) ||
          e.product.barcode.toLowerCase().contains(q) ||
          e.product.categoryName.toLowerCase().contains(q);
    }).toList();
  }

  List<_ProductEntry> get _selectedProducts =>
      _allProducts.where((e) => e.selected).toList();

  Future<void> _assignProducts() async {
    final selected = _selectedProducts;
    if (selected.isEmpty) {
      // Skip to step 3 with empty assignment (allowed)
      setState(() => _currentStep = 2);
      return;
    }

    setState(() {
      _isSavingAssignment = true;
      _assignError = null;
    });

    try {
      final api = ApiService();
      final assignments = selected
          .map((e) => {
                'productNumber': e.product.productNumber,
                'importPrice': null,
              })
          .toList();

      await api.assignSupplierProducts(_createdSupplierNumber!, assignments);

      if (mounted) {
        setState(() {
          _isSavingAssignment = false;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingAssignment = false;
          _assignError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _skipAssignment() {
    setState(() => _currentStep = 2);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: Set Import Prices
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _savePrices() async {
    final sel = _selectedProducts;
    if (sel.isEmpty) {
      _finishCreation();
      return;
    }

    // Validate
    for (final e in sel) {
      final v = double.tryParse(e.priceController.text.trim());
      if (v == null || v <= 0) {
        setState(() {
          _pricesError =
              'Please enter a valid import price for all assigned products.';
        });
        return;
      }
    }

    setState(() {
      _isSavingPrices = true;
      _pricesError = null;
    });

    try {
      final api = ApiService();
      final assignments = sel
          .map((e) => {
                'productNumber': e.product.productNumber,
                'importPrice': double.parse(e.priceController.text.trim()),
              })
          .toList();

      await api.updateSupplierImportPrices(_createdSupplierNumber!, assignments);

      if (mounted) {
        setState(() => _isSavingPrices = false);
        _finishCreation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingPrices = false;
          _pricesError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _finishCreation() {
    ref.read(supplierListProvider.notifier).loadSuppliers(isRefresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Supplier created successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
    if (_createdSupplierNumber != null) {
      context.go('/manager/supplier/$_createdSupplierNumber');
    } else {
      context.go('/manager/supplier');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Create New Supplier',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0 && _createdSupplierNumber != null) {
              // Already created – go back to detail or list
              context.go('/manager/supplier/$_createdSupplierNumber');
            } else {
              context.go('/manager/supplier');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // ── Step Indicator ────────────────────────────────────────────────
          _StepIndicator(currentStep: _currentStep),

          // ── Step Content ──────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(context, theme),
                _buildStep2(context, theme),
                _buildStep3(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Supplier Info ─────────────────────────────────────────────────
  Widget _buildStep1(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _infoFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.local_shipping_outlined,
                  title: 'Supplier Information',
                  subtitle: 'Fill in the basic details about the new supplier.',
                ),
                const SizedBox(height: 24),

                // Supplier Name
                _FieldLabel('Supplier Name *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDec(
                    context,
                    'e.g. Fresh Foods Co.',
                    Icons.storefront_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required.' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Row: Phone + Email
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Phone Number'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: _inputDec(
                              context,
                              '0901234567',
                              Icons.phone_outlined,
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Email Address'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _inputDec(
                              context,
                              'contact@example.com',
                              Icons.email_outlined,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact Person + Category
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Contact Person'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _contactPersonCtrl,
                            decoration: _inputDec(
                              context,
                              'Sales representative name',
                              Icons.person_outline,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Category'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _categoryCtrl,
                            decoration: _inputDec(
                              context,
                              'e.g. Beverages, Produce…',
                              Icons.category_outlined,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address
                _FieldLabel('Address'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: _inputDec(
                    context,
                    '123 Main Street, District 1, Ho Chi Minh City',
                    Icons.location_on_outlined,
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Status
                _FieldLabel('Status'),
                const SizedBox(height: 6),
                _StatusToggle(
                  value: _status,
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 16),

                // Notes
                _FieldLabel('Notes'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _inputDec(
                    context,
                    'Additional notes about this supplier…',
                    Icons.notes_outlined,
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),

                // Error
                if (_infoError != null) ...[
                  const SizedBox(height: 20),
                  _ErrorBanner(message: _infoError!),
                ],

                const SizedBox(height: 32),

                // Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/manager/supplier'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSavingInfo ? null : _createSupplier,
                      icon: _isSavingInfo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Create & Continue'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 2: Assign Products ───────────────────────────────────────────────
  Widget _buildStep2(BuildContext context, ThemeData theme) {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load products.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _productsError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadAllProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;
    final selectedCount = _selectedProducts.length;

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'Assign Products',
                  subtitle:
                      'Select products this supplier provides. ($selectedCount selected)',
                ),
              ),
            ],
          ),
        ),

        // ── Search bar ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _productSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products by name, barcode, or category…',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _productSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _productSearchCtrl.clear();
                          setState(() => _productSearch = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _productSearch = v),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Product list ──────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _productSearch.isEmpty
                        ? 'No products available.'
                        : 'No products found for "$_productSearch".',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final entry = filtered[i];
                    return _ProductSelectionTile(
                      entry: entry,
                      onToggle: (v) {
                        setState(() => entry.selected = v ?? false);
                      },
                    );
                  },
                ),
        ),

        // ── Error ─────────────────────────────────────────────────────────
        if (_assignError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: _ErrorBanner(message: _assignError!),
          ),

        // ── Actions ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: _skipAssignment,
                child: const Text('Skip (assign later)'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSavingAssignment ? null : _assignProducts,
                icon: _isSavingAssignment
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  selectedCount == 0
                      ? 'Continue (no products)'
                      : 'Assign $selectedCount Product${selectedCount != 1 ? "s" : ""}',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 3: Set Import Prices ─────────────────────────────────────────────
  Widget _buildStep3(BuildContext context, ThemeData theme) {
    final sel = _selectedProducts;

    return Column(
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: _SectionHeader(
            icon: Icons.price_change_outlined,
            title: 'Set Import Prices',
            subtitle: sel.isEmpty
                ? 'No products were assigned. You can finish now.'
                : 'Set the purchase price for each assigned product.',
          ),
        ),

        if (sel.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products assigned.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can assign and price products later from the supplier detail page.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              itemCount: sel.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final entry = sel[i];
                return _ImportPriceTile(entry: entry);
              },
            ),
          ),

        // ── Error ─────────────────────────────────────────────────────────
        if (_pricesError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: _ErrorBanner(message: _pricesError!),
          ),

        // ── Actions ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              if (sel.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 6),
                      Text('Back'),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSavingPrices ? null : _savePrices,
                icon: _isSavingPrices
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('Finish & View Supplier'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const _steps = [
    'Supplier Info',
    'Assign Products',
    'Import Prices',
  ];

  static const _icons = [
    Icons.info_outline_rounded,
    Icons.inventory_2_outlined,
    Icons.price_change_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            final isDone = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDone
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final isDone = currentStep > stepIndex;
          final isCurrent = currentStep == stepIndex;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDone
                      ? theme.colorScheme.primary
                      : isCurrent
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent && !isDone
                      ? Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : Icon(
                          _icons[stepIndex],
                          size: 20,
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _steps[stepIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isCurrent || isDone
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isCurrent || isDone
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Selection Tile (Step 2)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductSelectionTile extends StatefulWidget {
  final _ProductEntry entry;
  final ValueChanged<bool?> onToggle;

  const _ProductSelectionTile({
    required this.entry,
    required this.onToggle,
  });

  @override
  State<_ProductSelectionTile> createState() => _ProductSelectionTileState();
}

class _ProductSelectionTileState extends State<_ProductSelectionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.entry.product;
    final isSelected = widget.entry.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onToggle(!isSelected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.07)
                : _hovered
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: widget.onToggle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Product icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.productName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Chip(p.categoryName),
                        const SizedBox(width: 6),
                        if (p.barcode.isNotEmpty) _Chip(p.barcode),
                      ],
                    ),
                  ],
                ),
              ),

              // Selling price (reference)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Selling Price',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${p.sellingPrice.toStringAsFixed(0)}₫',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Import Price Tile (Step 3)
// ─────────────────────────────────────────────────────────────────────────────

class _ImportPriceTile extends StatelessWidget {
  final _ProductEntry entry;

  const _ImportPriceTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = entry.product;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 14),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.productName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Chip(p.categoryName),
                    const SizedBox(width: 6),
                    Text(
                      'Sell: ${p.sellingPrice.toStringAsFixed(0)}₫',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Import Price Field
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: entry.priceController,
              decoration: InputDecoration(
                labelText: 'Import Price (₫)',
                hintText: '0',
                prefixIcon: const Icon(Icons.price_change_outlined, size: 18),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.primary, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final s in ['ACTIVE', 'INACTIVE'])
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: value == s
                      ? (s == 'ACTIVE'
                          ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                          : theme.colorScheme.errorContainer
                              .withValues(alpha: 0.15))
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: value == s
                        ? (s == 'ACTIVE'
                            ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                            : theme.colorScheme.error.withValues(alpha: 0.4))
                        : theme.colorScheme.outlineVariant,
                    width: value == s ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s == 'ACTIVE'
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                      size: 16,
                      color: value == s
                          ? (s == 'ACTIVE'
                              ? const Color(0xFF15803D)
                              : theme.colorScheme.error)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s == 'ACTIVE' ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: value == s
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: value == s
                            ? (s == 'ACTIVE'
                                ? const Color(0xFF15803D)
                                : theme.colorScheme.error)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDec(
    BuildContext context, String hint, IconData icon) {
  final theme = Theme.of(context);
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor:
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
    contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );
}
