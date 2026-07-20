import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/inventory_product.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate problem products screen, backed by the real inventory API.
/// Products are classified Expired / Out of Stock / Low Stock from live data.
class SalesProblemProductsScreen extends ConsumerStatefulWidget {
  const SalesProblemProductsScreen({super.key});

  @override
  ConsumerState<SalesProblemProductsScreen> createState() =>
      _SalesProblemProductsScreenState();
}

class _SalesProblemProductsScreenState
    extends ConsumerState<SalesProblemProductsScreen> {
  String selectedFilter = 'All';
  String searchQuery = '';
  late Future<List<InventoryProduct>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<InventoryProduct>> _load() async {
    final data = await ApiService().fetchInventoryProducts(size: 100);
    return (data['items'] as List<InventoryProduct>)
        .where((p) => p.status == 'ACTIVE')
        .toList();
  }

  void _reload() => setState(() => _future = _load());

  bool _isExpired(InventoryProduct p) {
    if (p.expiryDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day)
        .isBefore(today);
  }

  /// Expired > Out of Stock > Low Stock; null when healthy.
  String? _problemStatus(InventoryProduct p) {
    if (_isExpired(p)) return 'Expired';
    if (p.stock <= 0) return 'Out of Stock';
    if (p.stock <= p.reorderLevel) return 'Low Stock';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.read(shellLayoutProvider.notifier).update(
          title: 'Problem Products Alert Center',
          breadcrumbs: ['Sales', 'Problem Products'],
        );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or barcode...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => searchQuery = val),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['All', 'Out of Stock', 'Low Stock', 'Expired'].map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => selectedFilter = filter);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<InventoryProduct>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load data.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: _reload, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                final query = searchQuery.toLowerCase();
                final problemProducts = (snapshot.data ?? []).where((p) {
                  final status = _problemStatus(p);
                  if (status == null) return false;
                  final matchesSearch =
                      p.productName.toLowerCase().contains(query) ||
                          p.barcode.toLowerCase().contains(query);
                  if (!matchesSearch) return false;
                  if (selectedFilter == 'All') return true;
                  return status == selectedFilter;
                }).toList()
                  ..sort((a, b) => _statusRank(_problemStatus(a)!)
                      .compareTo(_statusRank(_problemStatus(b)!)));

                if (problemProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'All quiet! No problem products detected.',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                        child: Text(
                          'Stock Level Warnings',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ...problemProducts
                          .map((p) => _buildProductCard(context, p)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _statusRank(String status) {
    switch (status) {
      case 'Expired':
        return 0;
      case 'Out of Stock':
        return 1;
      default:
        return 2;
    }
  }

  Widget _buildProductCard(BuildContext context, InventoryProduct p) {
    final theme = Theme.of(context);
    final status = _problemStatus(p)!;
    final color = _statusColor(status, theme);

    String subtitle;
    switch (status) {
      case 'Expired':
        final dateStr = p.expiryDate != null
            ? DateFormat('yyyy-MM-dd').format(p.expiryDate!)
            : 'unknown date';
        subtitle = 'Batch expired on $dateStr • Stock: '
            '${p.stock.toStringAsFixed(0)} ${p.unitName}';
        break;
      case 'Out of Stock':
        subtitle = 'No stock remaining (reorder level '
            '${p.reorderLevel.toStringAsFixed(0)})';
        break;
      default:
        subtitle = 'Remaining: ${p.stock.toStringAsFixed(0)} ${p.unitName} / '
            'Min: ${p.reorderLevel.toStringAsFixed(0)}';
    }

    return BentoCard(
      margin: const EdgeInsets.only(bottom: 12.0),
      onTap: () => context.push('/sales/products/${p.productNumber}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(status), color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.barcode,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(p.productName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Expired':
        return Icons.event_busy;
      case 'Out of Stock':
        return Icons.block;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Expired':
        return Colors.deepOrange;
      case 'Out of Stock':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.secondary;
    }
  }
}
