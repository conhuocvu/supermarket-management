import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/staff_member.dart';
import '../providers/staff_provider.dart';
import '../providers/shell_layout_provider.dart';
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

  static const _filters = ['ALL', 'ON_DUTY', 'OFF_DUTY', 'ON_LEAVE'];
  static const _filterLabels = {
    'ALL': 'All Staff',
    'ON_DUTY': 'On Duty',
    'OFF_DUTY': 'Off Duty',
    'ON_LEAVE': 'On Leave',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
        title: 'Staff Management',
        breadcrumbs: ['Manager', 'Staff'],
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

          // ── Staff List ───────────────────────────────────────────
          Expanded(
            child: _buildBody(context, theme, state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    StaffListState state,
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

    return _StaffGrid(
      staff: state.staff,
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
            iconColor: const Color(0xFF22C55E),
            iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
            badge: isLoading ? null : 'Live',
            badgeColor: const Color(0xFF22C55E),
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
// Staff Grid
// ────────────────────────────────────────────────────────────────────────────

class _StaffGrid extends StatelessWidget {
  final List<StaffMember> staff;

  const _StaffGrid({required this.staff});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.6,
          ),
          itemCount: staff.length,
          itemBuilder: (ctx, i) => _StaffCard(member: staff[i]),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Staff Card
// ────────────────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final StaffMember member;

  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusConfig = _statusConfig(member.workStatus);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar + menu ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaffAvatar(member: member),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.roleName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '  •  ',
                            style: TextStyle(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          _StatusDot(
                            label: statusConfig.label,
                            color: statusConfig.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Shift info row ──────────────────────────────────
            _ShiftInfoRow(member: member, theme: theme),

            const SizedBox(height: 12),

            // ── View Profile button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/manager/staff/${member.userId}');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String workStatus) {
    switch (workStatus) {
      case 'ON_DUTY':
        return _StatusConfig('On Duty', const Color(0xFF22C55E));
      case 'ON_LEAVE':
        return _StatusConfig('On Leave', const Color(0xFFF4A261));
      default:
        return _StatusConfig('Off Duty', const Color(0xFF6B7280));
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig(this.label, this.color);
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
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
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: _WorkStatusIndicator(workStatus: member.workStatus),
        ),
      ],
    );
  }

  Widget _initialsWidget(String initials, Color color, ThemeData theme) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 18,
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

class _WorkStatusIndicator extends StatelessWidget {
  final String workStatus;

  const _WorkStatusIndicator({required this.workStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (workStatus) {
      case 'ON_DUTY':
        color = const Color(0xFF22C55E);
        break;
      case 'ON_LEAVE':
        color = const Color(0xFFF4A261);
        break;
      default:
        color = const Color(0xFF9CA3AF);
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Status Dot (inline label)
// ────────────────────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shift Info Row
// ────────────────────────────────────────────────────────────────────────────

class _ShiftInfoRow extends StatelessWidget {
  final StaffMember member;
  final ThemeData theme;

  const _ShiftInfoRow({required this.member, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasShift = member.shiftName != null && member.shiftName!.isNotEmpty;
    final isOnLeave = member.workStatus == 'ON_LEAVE';

    if (isOnLeave) {
      return _infoRow(
        Icons.beach_access_outlined,
        'On Leave',
        const Color(0xFFF4A261),
        '',
        theme,
      );
    }

    if (!hasShift) {
      return _infoRow(
        Icons.schedule_outlined,
        'No Shift Today',
        theme.colorScheme.outlineVariant,
        '',
        theme,
      );
    }

    return _infoRow(
      Icons.schedule_outlined,
      'Current Shift',
      theme.colorScheme.primary,
      member.shiftTimeRange,
      theme,
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    Color iconColor,
    String value,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
