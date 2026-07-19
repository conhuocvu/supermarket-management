import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/supplier_dialogs.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const _pageSize = 6;

  static const _filters = ['ALL', 'ACTIVE', 'INACTIVE'];
  static const _filterLabels = {
    'ALL': 'All Suppliers',
    'ACTIVE': 'Active Only',
    'INACTIVE': 'Inactive Only',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Supplier Management',
            breadcrumbs: ['Manager', 'Suppliers'],
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierListProvider);
    final theme = Theme.of(context);

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
                totalSuppliers: state.totalSuppliers,
                activeCount: state.activeCount,
                inactiveCount: state.inactiveCount,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 20),

              // ── Search + Filter Row ──────────────────────────────────
              _SearchFilterBar(
                searchController: _searchController,
                searchFocus: _searchFocus,
                selectedFilter: state.statusFilter,
                filterLabels: _filterLabels,
                filters: _filters,
                onSearch: (q) {
                  ref.read(supplierListProvider.notifier).search(q);
                },
                onFilterChanged: (f) {
                  _searchController.clear();
                  ref.read(supplierListProvider.notifier).setStatusFilter(f);
                },
              ),
              const SizedBox(height: 20),

              // ── Main Body ────────────────────────────────────────────
              Expanded(
                child: _buildBody(context, theme, state, isWide, isTablet),
              ),

              // ── Pagination Controls ──────────────────────────────────
              if (!state.isLoading && state.error == null && state.suppliers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PaginationBar(
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                  totalItems: state.totalSuppliers,
                  pageSize: _pageSize,
                  onPageChanged: (p) {
                    ref.read(supplierListProvider.notifier).setPage(p);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    SupplierListState state,
    bool isWide,
    bool isTablet,
  ) {
    if (state.isLoading) return const LoadingView();

    if (state.error != null) {
      return ErrorView(
        title: 'Unable to load supplier list.',
        description: state.error!,
        onRetry: () =>
            ref.read(supplierListProvider.notifier).loadSuppliers(isRefresh: true),
      );
    }

    if (state.suppliers.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return _SupplierGrid(
      suppliers: state.suppliers,
      isWide: isWide,
      isTablet: isTablet,
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query or filter status.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(supplierListProvider.notifier).setStatusFilter('ALL');
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
// Summary Cards
// ────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int totalSuppliers;
  final int activeCount;
  final int inactiveCount;
  final bool isLoading;

  const _SummaryCards({
    required this.totalSuppliers,
    required this.activeCount,
    required this.inactiveCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth >= 600;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 2.8 : 4.0,
        children: [
          _SummaryCard(
            label: 'Total Suppliers',
            value: isLoading ? '—' : '$totalSuppliers',
            icon: Icons.local_shipping_outlined,
            iconColor: theme.colorScheme.primary,
            iconBg: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          _SummaryCard(
            label: 'Active Only',
            value: isLoading ? '—' : '$activeCount',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF22C55E),
            iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
          ),
          _SummaryCard(
            label: 'Inactive Only',
            value: isLoading ? '—' : '$inactiveCount',
            icon: Icons.block_outlined,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFDC2626).withValues(alpha: 0.1),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
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
                  style: theme.textTheme.headlineSmall?.copyWith(
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
              hintText: 'Search suppliers by name, phone, email...',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
              color: selectedFilter != 'ALL' ? theme.colorScheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedFilter != 'ALL' ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              ),
              boxShadow: selectedFilter != 'ALL'
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
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
                  color: selectedFilter != 'ALL' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  filterLabels[selectedFilter] ?? selectedFilter,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selectedFilter != 'ALL' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selectedFilter != 'ALL' ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: selectedFilter != 'ALL' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );

        final newSupplierBtn = SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () async {
              final added = await showDialog<bool>(
                context: context,
                builder: (_) => const AddSupplierDialog(),
              );
              if (added == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier created successfully.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Supplier'),
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
              newSupplierBtn,
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
                Expanded(child: newSupplierBtn),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Supplier Grid
// ────────────────────────────────────────────────────────────────────────────

class _SupplierGrid extends StatelessWidget {
  final List<Supplier> suppliers;
  final bool isWide;
  final bool isTablet;

  const _SupplierGrid({
    required this.suppliers,
    required this.isWide,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : (isTablet ? 2 : 1),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isWide ? 1.6 : (isTablet ? 1.8 : 2.0),
      ),
      itemCount: suppliers.length,
      itemBuilder: (ctx, i) => _SupplierCard(supplier: suppliers[i]),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Supplier Card (premium design with scale hover animations)
// ────────────────────────────────────────────────────────────────────────────

class _SupplierCard extends StatefulWidget {
  final Supplier supplier;

  const _SupplierCard({required this.supplier});

  @override
  State<_SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends State<_SupplierCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInactive = widget.supplier.status == 'INACTIVE';

    final cardBgColor = isInactive
        ? theme.colorScheme.surface.withValues(alpha: 0.7)
        : theme.colorScheme.surface;
    final textAlpha = isInactive ? 0.6 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.diagonal3Values(_isHovered ? 1.015 : 1.0, _isHovered ? 1.015 : 1.0, 1.0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.8)
                : (isInactive
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.supplier.supplierName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: textAlpha),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final updated = await showDialog<bool>(
                              context: context,
                              builder: (_) => EditSupplierDialog(supplier: widget.supplier),
                            );
                            if (updated == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Supplier updated successfully.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else if (value == 'toggle_status') {
                            final toggled = await showDialog<bool>(
                              context: context,
                              builder: (_) => ToggleSupplierStatusDialog(supplier: widget.supplier),
                            );
                            if (toggled == true && context.mounted) {
                              final verb = widget.supplier.status == 'ACTIVE' ? 'deactivated' : 'activated';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Supplier $verb successfully.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Supplier'),
                          ),
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Text(widget.supplier.status == 'ACTIVE' ? 'Deactivate' : 'Activate'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: textAlpha),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (widget.supplier.phone != null && widget.supplier.phone!.isNotEmpty)
                          ? widget.supplier.phone!
                          : 'No phone number',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (widget.supplier.phone != null && widget.supplier.phone!.isNotEmpty)
                            ? theme.colorScheme.onSurface.withValues(alpha: textAlpha)
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: textAlpha),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: textAlpha),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (widget.supplier.email != null && widget.supplier.email!.isNotEmpty)
                          ? widget.supplier.email!
                          : 'No email address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (widget.supplier.email != null && widget.supplier.email!.isNotEmpty)
                            ? theme.colorScheme.onSurface.withValues(alpha: textAlpha)
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: textAlpha),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInactive
                          ? theme.colorScheme.errorContainer.withValues(alpha: 0.12)
                          : const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isInactive ? theme.colorScheme.error : const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.supplier.status,
                          style: TextStyle(
                            fontSize: 10,
                            color: isInactive ? theme.colorScheme.error : const Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ID: #${widget.supplier.supplierNumber ?? 0}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline.withValues(alpha: textAlpha),
                      fontSize: 11,
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

// ────────────────────────────────────────────────────────────────────────────
// Pagination Controls
// ────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = totalItems == 0 ? 0 : currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, totalItems);

    return Row(
      children: [
        Text(
          'Showing $start–$end of $totalItems suppliers',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        _PageButton(
          icon: Icons.first_page_rounded,
          enabled: currentPage > 0,
          onTap: () => onPageChanged(0),
        ),
        const SizedBox(width: 4),
        _PageButton(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 0,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 8),
        ...List.generate(totalPages, (i) {
          final isActive = i == currentPage;
          return GestureDetector(
            onTap: () => onPageChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _PageButton(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages - 1,
          onTap: () => onPageChanged(currentPage + 1),
        ),
        const SizedBox(width: 4),
        _PageButton(
          icon: Icons.last_page_rounded,
          enabled: currentPage < totalPages - 1,
          onTap: () => onPageChanged(totalPages - 1),
        ),
      ],
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
          color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
