import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/staff_member.dart';
import '../providers/staff_provider.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import 'staff_detail_screen.dart';
import '../core/providers/api_provider.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _loadingStaffId;

  static const _pageSize = 6;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSetRole(StaffMember member) async {
    final rolesAsync = ref.read(rolesMetaProvider);
    final roles = rolesAsync.valueOrNull ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => SetRoleDialog(
        userId: member.userId,
        currentRoleNumber: member.roleNumber,
        roles: roles,
        onSaved: () {
          ref.read(staffListProvider.notifier).loadStaff(isRefresh: true);
        },
      ),
    );
  }

  Future<void> _handleAssignShift(StaffMember member) async {
    if (_loadingStaffId != null) return;

    setState(() {
      _loadingStaffId = member.userId;
    });

    final theme = Theme.of(context);
    try {
      final api = ref.read(apiServiceProvider);
      final staffDetail = await api.fetchStaffDetail(member.userId);
      
      setState(() {
        _loadingStaffId = null;
      });
      
      final shiftsAsync = ref.read(shiftsMetaProvider);
      final shifts = shiftsAsync.valueOrNull ?? [];
      
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AssignShiftDialog(
            userId: member.userId,
            staffName: member.fullName,
            weeklySchedule: staffDetail['weeklySchedule'] as List? ?? [],
            availableShifts: shifts,
            onSaved: () {
              ref.read(staffListProvider.notifier).loadStaff(isRefresh: true);
            },
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loadingStaffId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load staff schedule: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffListProvider);
    final theme = Theme.of(context);

    // Warm up metadata providers for roles and shifts so filters can populate
    ref.watch(rolesMetaProvider);
    ref.watch(shiftsMetaProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Staff Management',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // ── Search + Filter Grid ──────────────────────────────────
          _FiltersSection(
            searchController: _searchController,
            searchFocus: _searchFocus,
            onSearch: (q) {
              ref.read(staffListProvider.notifier).search(q);
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
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: _buildTable(context, theme, pageStaff, state)),
          const Divider(height: 1),
          _PaginationBar(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            totalItems: state.totalStaff,
            pageSize: _pageSize,
            currentCount: pageStaff.length,
            onPageChanged: (p) {
              ref.read(staffListProvider.notifier).setPage(p);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ThemeData theme, List<StaffMember> items, StaffListState state) {
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
                  DataColumn(label: Text('Staff ID')),
                  DataColumn(label: Text('Full Name')),
                  DataColumn(label: Text('Phone Number')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Current Shift')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final idNumber = (state.currentPage * _pageSize) + index + 1;
                  final staffIdStr = '#STF-${idNumber.toString().padLeft(3, '0')}';

                  final isOnLeave = member.workStatus == 'ON_LEAVE';
                  final shiftText = isOnLeave ? 'Leave' : (member.shiftName ?? '—');

                  return DataRow(
                    cells: [
                      // Staff ID
                      DataCell(
                        Text(
                          staffIdStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Full Name
                      DataCell(
                        Row(
                          children: [
                            _StaffAvatar(member: member),
                            const SizedBox(width: 12),
                            Text(
                              member.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // Phone Number
                      DataCell(Text(member.phone)),
                      // Email
                      DataCell(Text(member.email ?? '—')),
                      // Role (styled box)
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.roleName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Current Shift
                      DataCell(Text(shiftText)),
                      // Status
                      DataCell(_buildStatusCell(context, member)),
                      // Actions (three buttons)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.push('/manager/staff/${member.userId}'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('View Details'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _handleSetRole(member),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Set Role'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _loadingStaffId != null ? null : () => _handleAssignShift(member),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: _loadingStaffId == member.userId
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Assign Shift'),
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

  Widget _buildStatusCell(BuildContext context, StaffMember member) {
    final theme = Theme.of(context);
    final isSuspended = member.status == 'SUSPENDED' || member.status == 'INACTIVE';
    final isOnLeave = member.workStatus == 'ON_LEAVE';

    if (isSuspended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Suspended',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isOnLeave) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'On Leave',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Active',
          style: TextStyle(
            color: Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
              ref.read(staffListProvider.notifier).resetFilters();
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
// Filters Section
// ────────────────────────────────────────────────────────────────────────────

class _FiltersSection extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearch;

  const _FiltersSection({
    required this.searchController,
    required this.searchFocus,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffListProvider);
    final notifier = ref.read(staffListProvider.notifier);
    final theme = Theme.of(context);

    final rolesAsync = ref.watch(rolesMetaProvider);
    final shiftsAsync = ref.watch(shiftsMetaProvider);

    final roles = rolesAsync.valueOrNull ?? [];
    final shifts = shiftsAsync.valueOrNull ?? [];

    final List<DropdownMenuItem<int?>> roleItems = [
      const DropdownMenuItem(value: null, child: Text('All Roles')),
      ...roles.map((r) => DropdownMenuItem(
            value: r['roleNumber'] as int?,
            child: Text(r['roleName'] as String? ?? ''),
          )),
    ];

    final List<DropdownMenuItem<String>> statusItems = const [
      DropdownMenuItem(value: 'ALL', child: Text('All Status')),
      DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
      DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave')),
      DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
    ];

    final List<DropdownMenuItem<int?>> shiftItems = [
      const DropdownMenuItem(value: null, child: Text('All Shifts')),
      ...shifts.map((s) => DropdownMenuItem(
            value: s['shiftNumber'] as int?,
            child: Text(s['shiftName'] as String? ?? ''),
          )),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        final searchWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Staff',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextField(
                controller: searchController,
                focusNode: searchFocus,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search staff by name, phone...',
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                onSubmitted: onSearch,
                onChanged: (v) {
                  if (v.isEmpty) onSearch('');
                },
              ),
            ),
          ],
        );

        Widget buildDropdown<T>({
          required String label,
          required T value,
          required List<DropdownMenuItem<T>> items,
          required ValueChanged<T?> onChanged,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 48,
                child: DropdownButtonFormField<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
            ],
          );
        }

        final roleWidget = buildDropdown<int?>(
          label: 'Role',
          value: state.selectedRoleNumber,
          items: roleItems,
          onChanged: (v) => notifier.setRoleFilter(v),
        );

        final statusWidget = buildDropdown<String>(
          label: 'Status',
          value: state.statusFilter,
          items: statusItems,
          onChanged: (v) => notifier.setStatusFilter(v ?? 'ALL'),
        );

        final shiftWidget = buildDropdown<int?>(
          label: 'Shift',
          value: state.selectedShiftNumber,
          items: shiftItems,
          onChanged: (v) => notifier.setShiftFilter(v),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: searchWidget),
              const SizedBox(width: 16),
              Expanded(child: roleWidget),
              const SizedBox(width: 16),
              Expanded(child: statusWidget),
              const SizedBox(width: 16),
              Expanded(child: shiftWidget),
            ],
          );
        }

        if (isMedium) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: searchWidget),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: roleWidget),
                  const SizedBox(width: 12),
                  Expanded(child: statusWidget),
                  const SizedBox(width: 12),
                  Expanded(child: shiftWidget),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            searchWidget,
            const SizedBox(height: 12),
            roleWidget,
            const SizedBox(height: 12),
            statusWidget,
            const SizedBox(height: 12),
            shiftWidget,
          ],
        );
      },
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
  final int currentCount;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.currentCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Showing label matching wireframe
          Text(
            'Showing $currentCount of $totalItems staff members',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          // Page buttons
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
      width: 32,
      height: 32,
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
          fontSize: 12,
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
