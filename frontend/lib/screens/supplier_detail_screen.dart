import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/supplier.dart';
import '../models/supplier_product.dart';
import '../providers/supplier_provider.dart';
import '../widgets/supplier_dialogs.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UC-SM-05: View Supplier Details
// UC-SM-06: Update Supplier (via Edit dialog)
// UC-SM-07: Deactivate Supplier (via toggle status dialog)
// ─────────────────────────────────────────────────────────────────────────────

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final int supplierNumber;

  const SupplierDetailScreen({super.key, required this.supplierNumber});

  @override
  ConsumerState<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  Supplier? _supplier;
  List<SupplierProduct> _assignedProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supplier = await ref
          .read(supplierListProvider.notifier)
          .fetchSupplierById(widget.supplierNumber);
      
      final products = await ApiService().fetchSupplierProducts(widget.supplierNumber);

      if (mounted) {
        setState(() {
          _supplier = supplier;
          _assignedProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager/supplier'),
        ),
        title: Text(
          _supplier?.supplierName ?? 'Supplier Details',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        actions: [
          if (_supplier != null) ...[
            IconButton(
              tooltip: 'Edit Supplier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              tooltip: _supplier!.status == 'ACTIVE' ? 'Deactivate Supplier' : 'Activate Supplier',
              icon: Icon(
                _supplier!.status == 'ACTIVE' ? Icons.block_outlined : Icons.check_circle_outline,
                color: _supplier!.status == 'ACTIVE' ? theme.colorScheme.error : const Color(0xFF22C55E),
              ),
              onPressed: () => _showToggleStatusDialog(context),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: _buildBody(context, theme),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load supplier details.',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadSupplier,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_supplier == null) {
      return const Center(child: Text('Supplier not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Profile Card ─────────────────────────────────────────
            _ProfileHeaderCard(supplier: _supplier!, theme: theme),
            const SizedBox(height: 20),

            // ── Details Section ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Contact Information Card
                      _DetailCard(
                        title: 'Contact Information',
                        icon: Icons.contact_page_outlined,
                        children: [
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Contact Person',
                            value: _supplier!.contactPerson?.isNotEmpty == true
                                ? _supplier!.contactPerson!
                                : '—',
                          ),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: _supplier!.phone?.isNotEmpty == true ? _supplier!.phone! : '—',
                          ),
                          _DetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: _supplier!.email?.isNotEmpty == true ? _supplier!.email! : '—',
                          ),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: _supplier!.address?.isNotEmpty == true ? _supplier!.address! : '—',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Business Information Card
                      _DetailCard(
                        title: 'Business Information',
                        icon: Icons.business_outlined,
                        children: [
                          _DetailRow(
                            icon: Icons.category_outlined,
                            label: 'Category',
                            value: _supplier!.category?.isNotEmpty == true ? _supplier!.category! : '—',
                          ),
                          _DetailRow(
                            icon: Icons.numbers_outlined,
                            label: 'Supplier ID',
                            value: '#${_supplier!.supplierNumber ?? 0}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _NotesCard(notes: _supplier!.notes, theme: theme),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AssignedProductsCard(
              supplierNumber: _supplier!.supplierNumber!,
              assignedProducts: _assignedProducts,
              theme: theme,
              onRefresh: _loadSupplier,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditSupplierDialog(supplier: _supplier!),
    );
    if (updated == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Supplier updated successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      _loadSupplier();
    }
  }

  Future<void> _showToggleStatusDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final verb = _supplier!.status == 'ACTIVE' ? 'deactivated' : 'activated';
    final toggled = await showDialog<bool>(
      context: context,
      builder: (_) => ToggleSupplierStatusDialog(supplier: _supplier!),
    );
    if (toggled == true && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Supplier $verb successfully.'),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadSupplier();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final Supplier supplier;
  final ThemeData theme;

  const _ProfileHeaderCard({required this.supplier, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isActive = supplier.status == 'ACTIVE';
    final initials = supplier.supplierName.isNotEmpty
        ? supplier.supplierName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Name + Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.supplierName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (supplier.category?.isNotEmpty == true) ...[
                  Text(
                    supplier.category!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                        : theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                          : theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF22C55E) : theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive ? const Color(0xFF15803D) : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ID badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Supplier ID',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${supplier.supplierNumber ?? 0}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Card
// ─────────────────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = value == '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isEmpty
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isEmpty
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.onSurface,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes Card
// ─────────────────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String? notes;
  final ThemeData theme;

  const _NotesCard({required this.notes, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes != null && notes!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.notes_outlined, size: 18, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (hasNotes)
            Text(
              notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.6,
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 36,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No notes added.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outlineVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assigned Products Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _AssignedProductsCard extends StatelessWidget {
  final int supplierNumber;
  final List<SupplierProduct> assignedProducts;
  final ThemeData theme;
  final VoidCallback onRefresh;

  const _AssignedProductsCard({
    required this.supplierNumber,
    required this.assignedProducts,
    required this.theme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasProducts = assignedProducts.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Assigned Products (${assignedProducts.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _assignProducts(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Assign Products'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: hasProducts ? () => _updatePrices(context) : null,
                icon: const Icon(Icons.price_change_outlined, size: 16),
                label: const Text('Set Import Prices'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (hasProducts)
            _buildProductsTable(context)
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No products assigned to this supplier.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Assign products and set their import purchase prices to manage stocks.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Table Header
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          ),
          children: [
            _tableHeaderCell('Product Name'),
            _tableHeaderCell('Category'),
            _tableHeaderCell('Selling Price'),
            _tableHeaderCell('Import Price'),
            _tableHeaderCell('Min Order Qty'),
          ],
        ),
        // Table Rows
        for (final p in assignedProducts)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  p.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(p.categoryName ?? '—'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text('${p.sellingPrice.toStringAsFixed(0)}₫'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  p.importPrice != null ? '${p.importPrice!.toStringAsFixed(0)}₫' : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.importPrice != null ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text(
                  p.minimumOrderQuantity != null ? p.minimumOrderQuantity!.toStringAsFixed(0) : '—',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _tableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _assignProducts(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AssignSupplierProductsDialog(
        supplierNumber: supplierNumber,
        currentlyAssigned: assignedProducts,
      ),
    );
    if (updated == true) {
      onRefresh();
    }
  }

  Future<void> _updatePrices(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => UpdateSupplierImportPricesDialog(
        supplierNumber: supplierNumber,
        assignedProducts: assignedProducts,
      ),
    );
    if (updated == true) {
      onRefresh();
    }
  }
}
