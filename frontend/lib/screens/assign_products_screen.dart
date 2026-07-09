import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/supplier_product.dart';
import 'package:frontend/providers/supplier_provider.dart';
import 'package:frontend/widgets/shared/app_search_field.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/smart_image.dart';

class AssignProductsScreen extends ConsumerStatefulWidget {
  final int supplierId;

  const AssignProductsScreen({super.key, required this.supplierId});

  @override
  ConsumerState<AssignProductsScreen> createState() => _AssignProductsScreenState();
}

class _AssignProductsScreenState extends ConsumerState<AssignProductsScreen> {
  final _searchController = TextEditingController();
  String _activeCategory = 'ALL';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(supplierProductsProvider(widget.supplierId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Assign Products',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                'SM',
                style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(supplierProductsProvider(widget.supplierId).notifier).fetchProducts(),
        ),
        data: (products) {
          // Client-side filtering based on search query and category chips
          final filtered = products.where((p) {
            final matchesQuery = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory = _activeCategory == 'ALL' ||
                p.category.toLowerCase() == _activeCategory.toLowerCase();
            return matchesQuery && matchesCategory;
          }).toList();

          final selectedProducts = products.where((p) => p.assigned).toList();

          return Column(
            children: [
              Expanded(
                child: PageContainer(
                  child: ListView(
                    children: [
                      const SizedBox(height: 16),
                      AppSearchField(
                        hint: 'Search all products...',
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryChips(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Products',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            '${filtered.length} products found',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return _buildProductListTile(p);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildSelectionSummary(selectedProducts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    final filters = [
      {'label': 'All Products', 'value': 'ALL'},
      {'label': 'Produce', 'value': 'Produce'},
      {'label': 'Dairy', 'value': 'Dairy'},
      {'label': 'Bakery', 'value': 'Bakery'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeCategory == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _activeCategory = f['value']!;
                  });
                }
              },
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.surfaceVariant,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductListTile(SupplierProduct sp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SmartImage(
                imageUrl: sp.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sp.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${sp.sku}',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: sp.assigned ? () => _showPriceDialog(sp) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sp.assigned ? AppTheme.primaryLight.withValues(alpha: 0.25) : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sp.assigned
                            ? 'Wholesale: \$${sp.importPrice.toStringAsFixed(2)} / ${sp.unit} ✎'
                            : '\$${sp.basePrice.toStringAsFixed(2)} / ${sp.unit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: sp.assigned ? AppTheme.primaryDark : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: sp.assigned,
              activeColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) {
                ref.read(supplierProductsProvider(widget.supplierId).notifier).toggleProductAssignment(sp.productId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(List<SupplierProduct> selected) {
    // Volume estimated summary based on count
    final totalVolume = selected.length * 35.04;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selection Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${selected.length} Items',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selected.length,
                  itemBuilder: (context, index) {
                    final p = selected[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(p.name, style: const TextStyle(fontSize: 12)),
                        onDeleted: () {
                          ref.read(supplierProductsProvider(widget.supplierId).notifier).toggleProductAssignment(p.productId);
                        },
                        deleteIcon: const Icon(Icons.close, size: 14),
                        backgroundColor: AppTheme.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Total Volume',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                Text(
                  '${totalVolume.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selected.isEmpty ? null : _confirmAssignments,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Assigning products will automatically notify the supplier and update their procurement dashboard.',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceDialog(SupplierProduct sp) {
    final controller = TextEditingController(text: sp.importPrice.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Import Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set custom wholesale import price for ${sp.name}.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                labelText: 'Wholesale Price (per ${sp.unit})',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                ref.read(supplierProductsProvider(widget.supplierId).notifier).updateImportPrice(sp.productId, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAssignments() async {
    final result = await ref.read(supplierProductsProvider(widget.supplierId).notifier).confirmAssignments();
    if (mounted) {
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product assignments updated successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error?.userMessage ?? 'Failed to update assignments.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
