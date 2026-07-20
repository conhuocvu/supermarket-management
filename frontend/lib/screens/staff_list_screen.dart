import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/staff_member.dart';
import '../providers/staff_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const _pageSize = 6;

  static const _filters = ['ALL', 'ON_DUTY', 'OFF_DUTY', 'ON_LEAVE'];
  static const _filterLabels = {
    'ALL': 'All Staff',
    'ON_DUTY': 'On Duty',
    'OFF_DUTY': 'Off Duty',
    'ON_LEAVE': 'On Leave',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffListProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Cards ─────────────────────────────────────────
          _SummaryCards(
            totalStaff: state.totalStaff,
            onShiftCount: state.onShiftCount,
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
              ref.read(staffListProvider.notifier).search(q);
            },
            onFilterChanged: (f) {
              _searchController.clear();
              ref.read(staffListProvider.notifier).setStatusFilter(f);
            },
          ),
          const SizedBox(height: 20),

          // ── Staff List / Table ───────────────────────────────────
          Expanded(
            child: _buildBody(context, theme, state, state.staff),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    StaffListState state,
    List<StaffMember> pageStaff,
  ) {
    if (state.isLoading) return const LoadingView();

    if (state.error != null) {
      return ErrorView(
        title: 'Unable to load staff list.',
        description: state.error!,
        onRetry: () =>
            ref.read(staffListProvider.notifier).loadStaff(isRefresh: true),
      );
    }

    if (state.staff.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: _buildTable(context, theme, pageStaff)),
          const Divider(height: 1),
          _PaginationBar(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalItems: state.totalStaff,
            pageSize: _pageSize,
            onPageChanged: (p) {
              ref.read(staffListProvider.notifier).setPage(p);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ThemeData theme, List<StaffMember> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 68,
                dataRowMaxHeight: 68,
                horizontalMargin: 24,
                columnSpacing: 24,
                showCheckboxColumn: false,
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('Staff Member')),
                  DataColumn(label: Text('Work Status')),
                  DataColumn(label: Text('Shift Today')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.map((member) {
                  final hasShift = member.shiftName != null && member.shiftName!.isNotEmpty;
                  final isOnLeave = member.workStatus == 'ON_LEAVE';

                  String shiftText = 'No Shift Today';
                  if (isOnLeave) {
                    shiftText = 'On Leave';
                  } else if (hasShift) {
                    shiftText = '${member.shiftName} (${member.shiftTimeRange})';
                  }

                  return DataRow(
                    onSelectChanged: (_) {
                      context.push('/manager/staff/${member.userId}');
                    },
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            _StaffAvatar(member: member),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  member.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.roleName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(_buildStatusBadge(context, member.workStatus)),
                      DataCell(Text(shiftText)),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (val) {
                            if (val == 'profile') {
                              context.push('/manager/staff/${member.userId}');
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Text('View Profile'),
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

  Widget _buildStatusBadge(BuildContext context, String workStatus) {
    final theme = Theme.of(context);
    Color color;
    Color bgColor;
    String label;

    switch (workStatus) {
      case 'ON_DUTY':
        label = 'On Duty';
        color = theme.colorScheme.primary;
        bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        break;
      case 'ON_LEAVE':
        label = 'On Leave';
        color = theme.colorScheme.secondary;
        bgColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
        break;
      default:
        label = 'Off Duty';
        color = theme.colorScheme.outline;
        bgColor = theme.colorScheme.outline.withValues(alpha: 0.1);
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
            label,
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
            Icons.people_outline,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No staff members found.',
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
              ref.read(staffListProvider.notifier).setStatusFilter('ALL');
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
// Pagination Bar
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // ── Item count label ──────────────────────────────
          Text(
            'Showing $start–$end of $totalItems staff',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          // ── Page buttons ──────────────────────────────────
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

          // ── Page number pills ─────────────────────────────
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
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
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

// ────────────────────────────────────────────────────────────────────────────
// Summary Cards
// ────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int totalStaff;
  final int onShiftCount;
  final bool isLoading;

  const _SummaryCards({
    required this.totalStaff,
    required this.onShiftCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Staff',
            value: isLoading ? '—' : '$totalStaff',
            icon: Icons.people_alt_outlined,
            iconColor: theme.colorScheme.primary,
            iconBg: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            label: 'On Shift',
            value: isLoading ? '—' : '$onShiftCount',
            icon: Icons.access_time_outlined,
            iconColor: theme.colorScheme.primary,
            iconBg: theme.colorScheme.primary.withValues(alpha: 0.1),
            badge: isLoading ? null : 'Live',
            badgeColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? badge;
  final Color? badgeColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor?.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 11,
                                color: badgeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
              hintText: 'Search by name or phone...',
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

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 2, child: searchField),
              const SizedBox(width: 12),
              filterDropdown,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            searchField,
            const SizedBox(height: 12),
            filterDropdown,
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Staff Avatar
// ────────────────────────────────────────────────────────────────────────────

class _StaffAvatar extends StatelessWidget {
  final StaffMember member;

  const _StaffAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(member.fullName);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                member.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _initialsWidget(
                  initials,
                  theme.colorScheme.primary,
                  theme,
                ),
              ),
            )
          : _initialsWidget(initials, theme.colorScheme.primary, theme),
    );
  }

  Widget _initialsWidget(String initials, Color color, ThemeData theme) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
