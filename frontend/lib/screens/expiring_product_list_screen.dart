import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/expiring_product.dart';
import '../providers/expiring_products_provider.dart';
import '../providers/shell_layout_provider.dart';

class ExpiringProductListScreen extends ConsumerStatefulWidget {
  const ExpiringProductListScreen({super.key});

  @override
  ConsumerState<ExpiringProductListScreen> createState() => _ExpiringProductListScreenState();
}

class _ExpiringProductListScreenState extends ConsumerState<ExpiringProductListScreen> {
  String _searchQuery = '';
  String _committedSearch = '';
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All'; // All, Expired, Critical, Warning
  Timer? _debounce;

  // Local lists to mock client-side updates (disposals/discounts)
  final Set<int> _dismissedDetailNumbers = {};
  int _localProposedDiscountsCount = 8;
  int _localDisposalsCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Near-Expiry Management',
        breadcrumbs: ['Inventory', 'Expiring Products'],
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatQuantity(double qty, String productName) {
    final nameLower = productName.toLowerCase();
    String unit = 'Pcs';
    if (nameLower.contains('milk') || nameLower.contains('beverage') || nameLower.contains('juice') || nameLower.contains('water')) {
      unit = 'Liters';
    } else if (nameLower.contains('salmon') || nameLower.contains('meat') || nameLower.contains('tomato')) {
      unit = 'Grams';
    }
    
    if (qty == qty.toInt()) {
      return '${qty.toInt()} $unit';
    }
    return '${qty.toStringAsFixed(1)} $unit';
  }

  void _openDiscountProposalDialog(ExpiringProduct product) {
    final theme = Theme.of(context);
    final percentageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Propose Discount',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Target Product',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    product.productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discount Percentage',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: percentageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 25',
                    suffixText: '%',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Retail Manager will receive a high-priority alert',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final pct = percentageController.text.trim();
                          if (pct.isEmpty) return;
                          
                          Navigator.pop(context);
                          setState(() {
                            _localProposedDiscountsCount += 1;
                            _dismissedDetailNumbers.add(product.stockInDetailNumber);
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('Discount proposal of $pct% for ${product.productName} submitted successfully.'),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: theme.colorScheme.primary,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                        child: const Text('Submit Proposal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDisposalDialog(ExpiringProduct product) {
    final theme = Theme.of(context);
    String selectedReason = 'Expired / Out of Date';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Record Disposal',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Reason for Disposal',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildReasonRadio(
                          value: 'Expired / Out of Date',
                          groupValue: selectedReason,
                          onChanged: (val) {
                            setDialogState(() => selectedReason = val!);
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildReasonRadio(
                          value: 'Damaged Packaging',
                          groupValue: selectedReason,
                          onChanged: (val) {
                            setDialogState(() => selectedReason = val!);
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _buildReasonRadio(
                          value: 'Quality Control Failure',
                          groupValue: selectedReason,
                          onChanged: (val) {
                            setDialogState(() => selectedReason = val!);
                          },
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Disposal Log Notes',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Provide additional details for audit trails...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _localDisposalsCount += 1;
                                _dismissedDetailNumbers.add(product.stockInDetailNumber);
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text('Disposal of ${product.productName} recorded successfully.'),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Confirm Disposal'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReasonRadio({
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required ThemeData theme,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterParams = (search: _committedSearch, status: _statusFilter);
    final expiringAsync = ref.watch(expiringProductsProvider(filterParams));

    return Scaffold(
      body: expiringAsync.when(
        data: (products) {
          // Exclude locally dismissed items
          final filteredProducts = products
              .where((p) => !_dismissedDetailNumbers.contains(p.stockInDetailNumber))
              .toList();

          final criticalCount = filteredProducts.where((p) => p.daysRemaining >= 0 && p.daysRemaining <= 7).length;
          final totalNearExpiryCount = filteredProducts.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Stats Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return GridView.count(
                      crossAxisCount: isMobile ? 1 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 3.0 : 1.6,
                      children: [
                        _buildStatCard(
                          theme: theme,
                          title: 'TOTAL NEAR EXPIRY',
                          value: totalNearExpiryCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.onSurface,
                          progress: totalNearExpiryCount == 0 ? 0.0 : (totalNearExpiryCount / 30.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.primary,
                          subtitle: '$criticalCount items expiring within 7 days',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'PROPOSED DISCOUNTS',
                          value: _localProposedDiscountsCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.primary,
                          progress: (_localProposedDiscountsCount / 20.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.primary,
                          subtitle: 'Loss Mitigation Active',
                        ),
                        _buildStatCard(
                          theme: theme,
                          title: 'DISPOSALS TODAY',
                          value: _localDisposalsCount.toString().padLeft(2, '0'),
                          color: theme.colorScheme.error,
                          progress: (_localDisposalsCount / 10.0).clamp(0.0, 1.0),
                          progressColor: theme.colorScheme.error,
                          subtitle: 'Latest Log: 9942-A',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Search Bar and Filters Area
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search expiring watchlist...',
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _debounce?.cancel();
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _committedSearch = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                            _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              setState(() {
                                _committedSearch = val;
                              });
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildFilterDropdown(theme),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Data Table Container
                Card(
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Expiry Watchlist',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Last updated: ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filteredProducts.isEmpty)
                        _buildEmptyState(theme)
                      else
                        Scrollbar(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width - 320,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                ),
                                columnSpacing: 24,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 72,
                                columns: const [
                                  DataColumn(label: Text('Product')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Batch ID')),
                                  DataColumn(
                                    numeric: true,
                                    label: Padding(
                                      padding: EdgeInsets.only(right: 16),
                                      child: Text('Actions'),
                                    ),
                                  ),
                                ],
                                rows: filteredProducts.map((product) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          product.productName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        _buildStatusBadge(product, theme),
                                      ),
                                      DataCell(
                                        Text(
                                          _formatQuantity(product.quantity, product.productName),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          product.batchNumber,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              FilledButton(
                                                onPressed: () => _openDiscountProposalDialog(product),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: theme.colorScheme.primary,
                                                  foregroundColor: theme.colorScheme.onPrimary,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Propose Discount', style: TextStyle(fontSize: 12)),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () => _openDisposalDialog(product),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.colorScheme.error,
                                                  side: BorderSide(color: theme.colorScheme.error),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: const Text('Disposal', style: TextStyle(fontSize: 12)),
                                              ),
                                            ],
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
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(100.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => _buildErrorState(err, theme),
      ),
    );
  }

  Widget _buildStatusBadge(ExpiringProduct product, ThemeData theme) {
    Color bg;
    Color fg;
    String text;
    final days = product.daysRemaining;

    if (days < 0) {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
      text = 'EXPIRED';
    } else if (days <= 7) {
      bg = theme.colorScheme.errorContainer.withValues(alpha: 0.7);
      fg = theme.colorScheme.onErrorContainer;
      text = '${days.toString().padLeft(2, '0')} DAYS LEFT';
    } else {
      bg = theme.colorScheme.secondaryContainer.withValues(alpha: 0.4);
      fg = theme.colorScheme.onSecondaryContainer;
      text = '${days.toString().padLeft(2, '0')} DAYS LEFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: days <= 7 ? theme.colorScheme.error : theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          icon: const Icon(Icons.filter_list),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Expiry')),
            DropdownMenuItem(value: 'Expired', child: Text('Expired')),
            DropdownMenuItem(value: 'Critical', child: Text('Critical (<=7d)')),
            DropdownMenuItem(value: 'Warning', child: Text('Warning')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String title,
    required String value,
    required Color color,
    required double progress,
    required Color progressColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: progressColor.withValues(alpha: 0.1),
              color: progressColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No expiring products found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Expiring product data cannot be loaded.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(expiringProductsProvider((search: _committedSearch, status: _statusFilter))),
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
}
