import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promotion.dart';
import '../providers/promotion_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';

class PromotionListScreen extends ConsumerStatefulWidget {
  const PromotionListScreen({super.key});

  @override
  ConsumerState<PromotionListScreen> createState() => _PromotionListScreenState();
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

    // Dynamic grid item counts based on width
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600;

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

              // ── Search + Filter Bar ──────────────────────────────────
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
              Expanded(
                child: _buildBody(context, theme, state, isWide, isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    PromotionListState state,
    bool isWide,
    bool isTablet,
  ) {
    if (state.isLoading) return const LoadingView();

    if (state.error != null) {
      return ErrorView(
        title: 'Unable to load promotion data.',
        description: state.error!,
        onRetry: () =>
            ref.read(promotionListProvider.notifier).loadPromotions(isRefresh: true),
      );
    }

    if (state.promotions.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    // Separate featured promotion from list
    final featuredList = state.promotions.where((p) => p.isFeatured).toList();
    final normalList = state.promotions.where((p) => !p.isFeatured).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Normal Grid ─────────────────────────────────────────────
          if (normalList.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : (isTablet ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: normalList.length,
              itemBuilder: (ctx, i) => _PromotionCard(promotion: normalList[i]),
            ),
            const SizedBox(height: 24),
          ],

          // ── Featured Banner ─────────────────────────────────────────
          if (featuredList.isNotEmpty) ...[
            ...featuredList.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FeaturedBanner(promotion: p),
                )),
          ],
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
    return LayoutBuilder(builder: (ctx, constraints) {
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
    });
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
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          offset: const Offset(0, 52),
          itemBuilder: (ctx) => filters.map((f) {
            final isSelected = f == selectedFilter;
            final label = filterLabels[f] ?? f;
            return PopupMenuItem<String>(
              value: f,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.25),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UC-PM-02 Create Promotion is not implemented yet.'),
                  duration: Duration(seconds: 2),
                ),
              );
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

// ────────────────────────────────────────────────────────────────────────────
// Promotion Card
// ────────────────────────────────────────────────────────────────────────────

class _PromotionCard extends StatelessWidget {
  final Promotion promotion;

  const _PromotionCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusConfig = _statusConfig(promotion.status);

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Tag Overlay
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty
                        ? Image.network(
                            promotion.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.campaign_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.campaign_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusConfig.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusConfig.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.promotionName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROMO CODE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: theme.colorScheme.outline,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            promotion.promoCode,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('View, Edit, Delete Actions are not implemented yet.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        promotion.status == 'ACTIVE'
                            ? Icons.hourglass_bottom_rounded
                            : (promotion.status == 'SCHEDULED'
                                ? Icons.calendar_today_rounded
                                : Icons.history_rounded),
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        promotion.status == 'ACTIVE'
                            ? promotion.timeStatusLabel
                            : (promotion.status == 'SCHEDULED'
                                ? promotion.startStatusLabel
                                : 'Ended'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'ACTIVE':
        return _StatusConfig('ACTIVE', const Color(0xFF22C55E));
      case 'SCHEDULED':
        return _StatusConfig('SCHEDULED', const Color(0xFFF4A261));
      default:
        return _StatusConfig('EXPIRED', const Color(0xFF9CA3AF));
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig(this.label, this.color);
}

// ────────────────────────────────────────────────────────────────────────────
// Featured Banner (Bottom)
// ────────────────────────────────────────────────────────────────────────────

class _FeaturedBanner extends StatelessWidget {
  final Promotion promotion;

  const _FeaturedBanner({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 750;

    final bannerContent = Container(
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
        child: isDesktop
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 4, child: _buildImage(theme)),
                    Expanded(flex: 6, child: _buildDetails(theme, context)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.8,
                    child: _buildImage(theme),
                  ),
                  _buildDetails(theme, context),
                ],
              ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            'Featured Event',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        bannerContent,
      ],
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          Positioned.fill(
            child: promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty
                ? Image.network(
                    promotion.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.campaign_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'FEATURED',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            promotion.category.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            promotion.promotionName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          if (promotion.description != null) ...[
            Text(
              promotion.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GLOBAL CODE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.outline,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      promotion.promoCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('UC-PM-01 Manage Featured is not implemented yet.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
