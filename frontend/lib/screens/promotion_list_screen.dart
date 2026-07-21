import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/promotion.dart';
import '../providers/promotion_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/promotion_dialogs.dart';

class PromotionListScreen extends ConsumerStatefulWidget {
  const PromotionListScreen({super.key});

  @override
  ConsumerState<PromotionListScreen> createState() =>
      _PromotionListScreenState();
}

class _PromotionListScreenState extends ConsumerState<PromotionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const _statusFilters = ['ALL', 'ACTIVE', 'SCHEDULED', 'EXPIRED'];
  static const _filterLabels = {
    'ALL': 'All Promotions',
    'ACTIVE': 'Active',
    'SCHEDULED': 'Scheduled',
    'EXPIRED': 'Expired',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promotionListProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Cards ─────────────────────────────────────────
          _SummaryCards(
            activeCount: state.activeCount,
            scheduledCount: state.scheduledCount,
            expiredCount: state.expiredCount,
            avgDiscount: state.avgDiscount,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 24),

          // ── Search + Filter Row ──────────────────────────────────
          _SearchFilterBar(
            searchController: _searchController,
            searchFocus: _searchFocus,
            selectedFilter: state.statusFilter,
            filterLabels: _filterLabels,
            filters: _statusFilters,
            onSearch: (q) => ref.read(promotionListProvider.notifier).search(q),
            onFilterChanged: (f) {
              _searchController.clear();
              ref.read(promotionListProvider.notifier).setStatusFilter(f);
            },
          ),
          const SizedBox(height: 24),

          // ── Main Body ────────────────────────────────────────────
          Expanded(child: _buildBody(context, theme, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    PromotionListState state,
  ) {
    if (state.isLoading) return const LoadingView();

    if (state.error != null) {
      return ErrorView(
        title: 'Unable to load promotion data.',
        description: state.error!,
        onRetry: () => ref
            .read(promotionListProvider.notifier)
            .loadPromotions(isRefresh: true),
      );
    }

    if (state.promotions.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildTable(context, theme, state.promotions),
                const Divider(height: 1),
                _PaginationControls(
                  page: state.page,
                  totalPages: state.totalPages,
                  totalElements: state.totalElements,
                  pageSize: state.pageSize,
                  onPageChanged: (p) =>
                      ref.read(promotionListProvider.notifier).goToPage(p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    ThemeData theme,
    List<Promotion> items,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                horizontalMargin: 24,
                columnSpacing: 24,
                showCheckboxColumn: false,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('Promo Code')),
                  DataColumn(label: Text('Event Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Duration')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.map((promotion) {
                  String durationText = '';
                  if (promotion.status == 'ACTIVE') {
                    durationText = promotion.timeStatusLabel;
                  } else if (promotion.status == 'SCHEDULED') {
                    durationText = promotion.startStatusLabel;
                  } else {
                    durationText = 'Ended';
                  }

                  return DataRow(
                    onSelectChanged: (_) {
                      context.go(
                        '/manager/promotion/${promotion.promotionNumber}',
                      );
                    },
                    cells: [
                      DataCell(
                        Text(
                          promotion.promoCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          promotion.promotionName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(promotion.category.toUpperCase())),
                      DataCell(_buildStatusBadge(context, promotion.status)),
                      DataCell(Text(durationText)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go(
                                '/manager/promotion/${promotion.promotionNumber}',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('View Details'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                final updated = await showDialog<bool>(
                                  context: context,
                                  builder: (_) =>
                                      EditPromotionDialog(promotion: promotion),
                                );
                                if (updated == true && context.mounted) {
                                  ref
                                      .read(promotionListProvider.notifier)
                                      .loadPromotions(isRefresh: true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Promotion updated successfully.',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: (promotion.status == 'EXPIRED' ||
                                      promotion.status == 'INACTIVE')
                                  ? null
                                  : () async {
                                      final deactivated = await showDialog<bool>(
                                        context: context,
                                        builder: (_) =>
                                            DeactivatePromotionDialog(
                                          promotion: promotion,
                                        ),
                                      );
                                      if (deactivated == true &&
                                          context.mounted) {
                                        ref
                                            .read(promotionListProvider.notifier)
                                            .loadPromotions(isRefresh: true);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Promotion deactivated successfully.',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Deactivate'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'ACTIVE':
        color = const Color(0xFF22C55E);
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        break;
      case 'SCHEDULED':
        color = const Color(0xFFF4A261);
        bgColor = const Color(0xFFF4A261).withValues(alpha: 0.1);
        break;
      default:
        color = const Color(0xFF9CA3AF);
        bgColor = const Color(0xFF9CA3AF).withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No promotions found.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(promotionListProvider.notifier).setStatusFilter('ALL');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Summary Statistics Cards
// ────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int activeCount;
  final int scheduledCount;
  final int expiredCount;
  final double avgDiscount;
  final bool isLoading;

  const _SummaryCards({
    required this.activeCount,
    required this.scheduledCount,
    required this.expiredCount,
    required this.avgDiscount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 2.2 : 1.5,
          children: [
            _SummaryCard(
              label: 'Active',
              value: isLoading ? '—' : '$activeCount',
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
            ),
            _SummaryCard(
              label: 'Scheduled',
              value: isLoading ? '—' : '$scheduledCount',
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFFF4A261),
              iconBg: const Color(0xFFF4A261).withValues(alpha: 0.1),
            ),
            _SummaryCard(
              label: 'Expired',
              value: isLoading ? '—' : '$expiredCount',
              icon: Icons.history_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBg: const Color(0xFFDC2626).withValues(alpha: 0.1),
            ),
            _SummaryCard(
              label: 'Avg Discount',
              value: isLoading ? '—' : '$avgDiscount%',
              icon: Icons.percent_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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

// ────────────────────────────────────────────────────────────────────────────
// Search + Filter Bar
// ────────────────────────────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String selectedFilter;
  final Map<String, String> filterLabels;
  final List<String> filters;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilterChanged;

  const _SearchFilterBar({
    required this.searchController,
    required this.searchFocus,
    required this.selectedFilter,
    required this.filterLabels,
    required this.filters,
    required this.onSearch,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final searchField = SizedBox(
          height: 48,
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: InputDecoration(
              hintText: 'Search promotions by code or name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onSubmitted: onSearch,
            onChanged: (v) {
              if (v.isEmpty) onSearch('');
            },
          ),
        );

        final filterDropdown = PopupMenuButton<String>(
          onSelected: onFilterChanged,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          offset: const Offset(0, 52),
          itemBuilder: (ctx) => filters.map((f) {
            final isSelected = f == selectedFilter;
            final label = filterLabels[f] ?? f;
            return PopupMenuItem<String>(
              value: f,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selectedFilter != 'ALL'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedFilter != 'ALL'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              boxShadow: selectedFilter != 'ALL'
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: selectedFilter != 'ALL'
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  filterLabels[selectedFilter] ?? selectedFilter,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selectedFilter != 'ALL'
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selectedFilter != 'ALL'
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: selectedFilter != 'ALL'
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );

        final newPromotionBtn = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () async {
              final added = await showDialog<bool>(
                context: context,
                builder: (_) => const AddPromotionDialog(),
              );
              if (added == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Promotion created successfully.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Promotion'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: searchField),
              const SizedBox(width: 12),
              filterDropdown,
              const SizedBox(width: 12),
              newPromotionBtn,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            searchField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: filterDropdown),
                const SizedBox(width: 12),
                Expanded(child: newPromotionBtn),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalElements;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationControls({
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = totalElements == 0 ? 0 : page * pageSize + 1;
    final end = ((page + 1) * pageSize).clamp(0, totalElements);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // ── Item count label ──────────────────────────────
          Text(
            'Showing $start–$end of $totalElements promotions',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          // ── Page buttons ──────────────────────────────────
          _PageButton(
            icon: Icons.first_page_rounded,
            enabled: page > 0,
            onTap: () => onPageChanged(0),
          ),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            enabled: page > 0,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 8),

          // ── Page number pills ─────────────────────────────
          ...List.generate(totalPages, (i) {
            final isActive = i == page;
            return GestureDetector(
              onTap: () => onPageChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            enabled: page < totalPages - 1,
            onTap: () => onPageChanged(page + 1),
          ),
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.last_page_rounded,
            enabled: page < totalPages - 1,
            onTap: () => onPageChanged(totalPages - 1),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
