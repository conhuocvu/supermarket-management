import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/api_provider.dart';
import '../models/promotion.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/promotion_dialogs.dart';

final promotionDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, promoNumber) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchPromotionDetail(promoNumber);
});

class PromotionDetailScreen extends ConsumerStatefulWidget {
  final int promotionNumber;

  const PromotionDetailScreen({super.key, required this.promotionNumber});

  @override
  ConsumerState<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends ConsumerState<PromotionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Initial shell update while loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Promotion Details',
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Promotion Management',
                  onPressed: () => context.go('/manager/promotion'),
                ),
              ),
            ],
            breadcrumbs: ['Manager', 'Promotion Management', 'Loading...'],
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(promotionDetailProvider(widget.promotionNumber));

    // Update header breadcrumbs with loaded name
    detailAsync.whenOrNull(
      data: (data) {
        final name = data['promotionName'] as String? ?? 'Detail';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(shellLayoutProvider.notifier).update(
                title: 'Promotion Details',
                actions: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Promotion Management',
                      onPressed: () => context.go('/manager/promotion'),
                    ),
                  ),
                ],
                breadcrumbs: ['Manager', 'Promotion Management', name],
              );
        });
      },
    );

    return detailAsync.when(
      loading: () => const LoadingView(),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Promotion not found.',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString().replaceAll('Exception: ', ''),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Promotion Management'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => ref.refresh(promotionDetailProvider(widget.promotionNumber)),
                    icon: const Icon(Icons.replay),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      data: (data) => _PromotionDetailBody(
        data: data,
        promotionNumber: widget.promotionNumber,
      ),
    );
  }
}

class _PromotionDetailBody extends ConsumerWidget {
  final Map<String, dynamic> data;
  final int promotionNumber;

  const _PromotionDetailBody({
    required this.data,
    required this.promotionNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = data['status'] as String? ?? 'ACTIVE';
    final discount = data['discountValue'] as num? ?? 0.0;
    final code = data['promoCode'] as String? ?? '—';
    final desc = data['description'] as String?;
    final start = data['startDate'] as String? ?? '—';
    final end = data['endDate'] as String? ?? '—';
    final products = data['products'] as List? ?? [];

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'ACTIVE':
        statusColor = theme.colorScheme.primary;
        statusLabel = 'Active';
        break;
      case 'SCHEDULED':
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'Scheduled';
        break;
      default:
        statusColor = theme.colorScheme.outline;
        statusLabel = 'Expired';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onPressed: () => context.go('/manager/promotion'),
          ),
          const SizedBox(height: 20),

          // Details Card
          Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['promotionName'] as String? ?? '—',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _InfoGrid(
                  theme: theme,
                  children: [
                    _InfoItem(
                      icon: Icons.percent_rounded,
                      label: 'Discount Value',
                      value: '${discount.toStringAsFixed(1)}%',
                      theme: theme,
                    ),
                    _InfoItem(
                      icon: Icons.vpn_key_outlined,
                      label: 'Promo Code',
                      value: code,
                      theme: theme,
                      valueColor: theme.colorScheme.primary,
                    ),
                    _InfoItem(
                      icon: Icons.date_range_outlined,
                      label: 'Start Date',
                      value: start,
                      theme: theme,
                    ),
                    _InfoItem(
                      icon: Icons.event_busy_outlined,
                      label: 'End Date',
                      value: end,
                      theme: theme,
                    ),
                  ],
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Associated Products Section (if table contains rows)
          if (products.isNotEmpty) ...[
            Text(
              'Associated Products',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  columns: const [
                    DataColumn(label: Text('Product Name')),
                    DataColumn(label: Text('Barcode')),
                    DataColumn(
                      label: Expanded(
                        child: Text('Selling Price', textAlign: TextAlign.end),
                      ),
                      numeric: true,
                    ),
                  ],
                  rows: products.map<DataRow>((prod) {
                    final name = prod['productName'] as String? ?? '—';
                    final barcode = prod['barcode'] as String? ?? '—';
                    final price = prod['sellingPrice'] as num? ?? 0.0;
                    return DataRow(
                      cells: [
                        DataCell(Text(name)),
                        DataCell(Text(barcode)),
                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Build a Promotion model from the loaded data for the dialog
                    final promotion = _promotionFromData(data);
                    final deactivated = await showDialog<bool>(
                      context: context,
                      builder: (_) => DeactivatePromotionDialog(promotion: promotion),
                    );
                    if (deactivated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promotion deactivated successfully.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      ref.invalidate(promotionDetailProvider(promotionNumber));
                    }
                  },
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Deactivate Promotion'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final promotion = _promotionFromData(data);
                    final updated = await showDialog<bool>(
                      context: context,
                      builder: (_) => EditPromotionDialog(promotion: promotion),
                    );
                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promotion updated successfully.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      ref.invalidate(promotionDetailProvider(promotionNumber));
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Promotion'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a minimal Promotion model from raw API data map for dialogs.
  Promotion _promotionFromData(Map<String, dynamic> d) {
    return Promotion(
      promotionNumber: d['promotionNumber'] as int? ?? promotionNumber,
      promotionName: d['promotionName'] as String? ?? '',
      discountValue: (d['discountValue'] as num?)?.toDouble() ?? 0.0,
      status: d['status'] as String? ?? 'ACTIVE',
      startDate: d['startDate'] as String?,
      endDate: d['endDate'] as String?,
      description: d['description'] as String?,
      promoCode: d['promoCode'] as String? ?? '',
      category: d['category'] as String? ?? '',
      isFeatured: false,
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ThemeData theme;
  final List<Widget> children;

  const _InfoGrid({
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 4.5,
            children: children,
          );
        }
        return Column(
          children: children,
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? theme.colorScheme.onSurface,
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
