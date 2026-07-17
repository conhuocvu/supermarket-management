import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/staff_provider.dart';
import '../providers/category_provider.dart'; // provides apiServiceProvider

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final staffDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchStaffDetail(userId);
});

final rolesMetaProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchRoles();
});

final shiftsMetaProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchShifts();
});

// ---------------------------------------------------------------------------
// Staff Detail Screen  (UC-ST-02)
// ---------------------------------------------------------------------------

class StaffDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const StaffDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(staffDetailProvider(widget.userId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Staff record not found.',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(err.toString().replaceAll('Exception: ', ''),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Staff List'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _StaffDetailBody(
        data: data,
        userId: widget.userId,
        onRoleUpdated: () => ref.refresh(staffDetailProvider(widget.userId)),
        onShiftsUpdated: () => ref.refresh(staffDetailProvider(widget.userId)),
      ),
    );
  }
}

class _StaffDetailBody extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String userId;
  final VoidCallback onRoleUpdated;
  final VoidCallback onShiftsUpdated;

  const _StaffDetailBody({
    required this.data,
    required this.userId,
    required this.onRoleUpdated,
    required this.onShiftsUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workStatus = data['workStatus'] as String? ?? 'OFF_DUTY';

    // Eagerly warm up meta providers so dialogs open instantly
    ref.watch(rolesMetaProvider);
    ref.watch(shiftsMetaProvider);

    Color statusColor;
    String statusLabel;
    switch (workStatus) {
      case 'ON_DUTY':
        statusColor = const Color(0xFF22C55E);
        statusLabel = 'On Duty';
        break;
      case 'ON_LEAVE':
        statusColor = const Color(0xFFF4A261);
        statusLabel = 'On Leave';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'Off Duty';
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
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 20),

          // Profile header card
          _ProfileHeader(
            data: data,
            statusColor: statusColor,
            statusLabel: statusLabel,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Info rows
          LayoutBuilder(builder: (ctx, constraints) {
            if (constraints.maxWidth >= 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ContactInfoCard(data: data, theme: theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _ShiftInfoCard(data: data, theme: theme)),
                ],
              );
            }
            return Column(
              children: [
                _ContactInfoCard(data: data, theme: theme),
                const SizedBox(height: 16),
                _ShiftInfoCard(data: data, theme: theme),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Weekly schedule
          _WeeklyScheduleCard(
            weeklySchedule: data['weeklySchedule'] as List? ?? [],
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSetRoleDialog(context, ref, theme),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Set Role'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showAssignShiftDialog(context, ref, theme),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Assign Shift'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showSetRoleDialog(
      BuildContext context, WidgetRef ref, ThemeData theme) async {
    final rolesAsync = ref.read(rolesMetaProvider);
    final roles = rolesAsync.valueOrNull ?? [];

    await showDialog(
      context: context,
      builder: (ctx) => SetRoleDialog(
        userId: userId,
        currentRoleNumber: data['roleNumber'] as int?,
        roles: roles,
        onSaved: () {
          onRoleUpdated();
          ref.invalidate(staffListProvider);
        },
      ),
    );
  }

  Future<void> _showAssignShiftDialog(
      BuildContext context, WidgetRef ref, ThemeData theme) async {
    final shiftsAsync = ref.read(shiftsMetaProvider);
    final shifts = shiftsAsync.valueOrNull ?? [];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AssignShiftDialog(
        userId: userId,
        staffName: data['fullName'] as String? ?? '',
        weeklySchedule: data['weeklySchedule'] as List? ?? [],
        availableShifts: shifts,
        onSaved: () {
          onShiftsUpdated();
          ref.invalidate(staffListProvider);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Header Card
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;
  final String statusLabel;
  final ThemeData theme;

  const _ProfileHeader({
    required this.data,
    required this.statusColor,
    required this.statusLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = data['fullName'] as String? ?? '';
    final roleName = data['roleName'] as String? ?? '';
    final avatarUrl = data['avatarUrl'] as String?;
    final initials = _initials(fullName);

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              Center(child: _initialsWidget(initials, theme)),
                        ),
                      )
                    : Center(child: _initialsWidget(initials, theme)),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(String initials, ThemeData theme) {
    return Text(
      initials,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
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

// ---------------------------------------------------------------------------
// Contact Info Card
// ---------------------------------------------------------------------------

class _ContactInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;

  const _ContactInfoCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Contact Information',
      icon: Icons.contact_page_outlined,
      theme: theme,
      children: [
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: data['phone'] as String? ?? '—',
          theme: theme,
        ),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: data['address'] as String? ?? '—',
          theme: theme,
        ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Joined',
          value: _formatDate(data['createdAt'] as String?),
          theme: theme,
        ),
        _InfoRow(
          icon: Icons.toggle_on_outlined,
          label: 'Account Status',
          value: data['status'] as String? ?? 'ACTIVE',
          theme: theme,
          valueColor: (data['status'] as String? ?? 'ACTIVE') == 'ACTIVE'
              ? const Color(0xFF22C55E)
              : const Color(0xFF9CA3AF),
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ---------------------------------------------------------------------------
// Shift Info Card
// ---------------------------------------------------------------------------

class _ShiftInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ThemeData theme;

  const _ShiftInfoCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final shiftName = data['shiftName'] as String?;
    final startTime = data['shiftStartTime'] as String?;
    final endTime = data['shiftEndTime'] as String?;
    final timeRange = (startTime != null && endTime != null)
        ? '${_trim(startTime)} – ${_trim(endTime)}'
        : '—';

    return _InfoCard(
      title: "Today's Shift",
      icon: Icons.schedule_outlined,
      theme: theme,
      children: [
        _InfoRow(
          icon: Icons.work_outline,
          label: 'Shift Name',
          value: shiftName ?? 'No Shift Today',
          theme: theme,
        ),
        _InfoRow(
          icon: Icons.access_time_outlined,
          label: 'Hours',
          value: shiftName != null ? timeRange : '—',
          theme: theme,
        ),
      ],
    );
  }

  String _trim(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

// ---------------------------------------------------------------------------
// Weekly Schedule Card
// ---------------------------------------------------------------------------

class _WeeklyScheduleCard extends StatelessWidget {
  final List weeklySchedule;
  final ThemeData theme;

  const _WeeklyScheduleCard({required this.weeklySchedule, required this.theme});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.date_range_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Upcoming Schedule (7 days)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (weeklySchedule.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No scheduled shifts for the next 7 days.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...weeklySchedule.map((ws) {
              final w = ws as Map<String, dynamic>;
              final shiftName = w['shiftName'] as String? ?? 'Unknown';
              final day = w['dayOfWeek'] as String? ?? '';
              final date = w['workDate'] as String? ?? '';
              final start = w['shiftStartTime'] as String?;
              final end = w['shiftEndTime'] as String?;
              final timeRange = (start != null && end != null)
                  ? '${_trim(start)} – ${_trim(end)}'
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(day,
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(date,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(shiftName,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Text(timeRange,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _trim(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

// ---------------------------------------------------------------------------
// Reusable Card and Row widgets
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeData theme;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? theme.colorScheme.onSurface,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Set Role Dialog  (UC-ST-03)
// ---------------------------------------------------------------------------

class SetRoleDialog extends ConsumerStatefulWidget {
  final String userId;
  final int? currentRoleNumber;
  final List<Map<String, dynamic>> roles;
  final VoidCallback onSaved;

  const SetRoleDialog({
    super.key,
    required this.userId,
    required this.currentRoleNumber,
    required this.roles,
    required this.onSaved,
  });

  @override
  ConsumerState<SetRoleDialog> createState() => _SetRoleDialogState();
}

class _SetRoleDialogState extends ConsumerState<SetRoleDialog> {
  int? _selectedRoleNumber;
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRoleNumber = widget.currentRoleNumber;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedRoleNumber == null) {
      setState(() => _errorMessage = 'Please select a new role.');
      return;
    }
    if (_selectedRoleNumber == widget.currentRoleNumber) {
      setState(() => _errorMessage = 'The selected role is the same as the current role.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.setStaffRole(
        widget.userId,
        _selectedRoleNumber!,
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff role updated successfully.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Name of currently selected role (for display in the dropdown button)
    final selectedRoleName = widget.roles
        .firstWhere(
          (r) => (r['roleNumber'] as num).toInt() == _selectedRoleNumber,
          orElse: () => {'roleName': 'Select a role...'},
        )['roleName']
        ?.toString() ??
        'Select a role...';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.manage_accounts_outlined,
                color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Set Role'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: TextStyle(
                              color: theme.colorScheme.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Current Role label
            Text('Current Role',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.roles
                        .firstWhere(
                          (r) =>
                              (r['roleNumber'] as num).toInt() ==
                              widget.currentRoleNumber,
                          orElse: () => {'roleName': 'Unknown'},
                        )['roleName']
                        ?.toString() ??
                    'Unknown',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // New Role popup selector
            Text('Select New Role *',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            PopupMenuButton<int>(
              onSelected: (val) => setState(() => _selectedRoleNumber = val),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              itemBuilder: (ctx) => widget.roles.map((role) {
                final rNum = (role['roleNumber'] as num).toInt();
                final rName = role['roleName']?.toString() ?? '';
                final rDesc = role['description']?.toString() ?? '';
                final isSelected = _selectedRoleNumber == rNum;
                return PopupMenuItem<int>(
                  value: rNum,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(rName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : null)),
                            if (rDesc.isNotEmpty)
                              Text(rDesc,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedRoleNumber != null &&
                            _selectedRoleNumber != widget.currentRoleNumber
                        ? theme.colorScheme.primary.withValues(alpha: 0.6)
                        : theme.colorScheme.outlineVariant,
                    width:
                        _selectedRoleNumber != null &&
                                _selectedRoleNumber !=
                                    widget.currentRoleNumber
                            ? 1.5
                            : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.manage_accounts_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedRoleName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _selectedRoleNumber == null
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reason field
            Text('Reason / Note (optional)',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for role change...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Role'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Assign Shift Dialog  (UC-ST-04)
// ---------------------------------------------------------------------------

class AssignShiftDialog extends ConsumerStatefulWidget {
  final String userId;
  final String staffName;
  final List weeklySchedule;
  final List<Map<String, dynamic>> availableShifts;
  final VoidCallback onSaved;

  const AssignShiftDialog({
    super.key,
    required this.userId,
    required this.staffName,
    required this.weeklySchedule,
    required this.availableShifts,
    required this.onSaved,
  });

  @override
  ConsumerState<AssignShiftDialog> createState() => _AssignShiftDialogState();
}

class _AssignShiftDialogState extends ConsumerState<AssignShiftDialog> {
  // Map: workDate string → shiftNumber (null = day off)
  final Map<String, int?> _assignments = {};
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate from existing schedule
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = _fmtDate(date);
      final existing = widget.weeklySchedule.firstWhere(
        (ws) => (ws as Map<String, dynamic>)['workDate'] == dateStr,
        orElse: () => null,
      );
      if (existing != null) {
        final e = existing as Map<String, dynamic>;
        _assignments[dateStr] = e['shiftNumber'] as int?;
      } else {
        _assignments[dateStr] = null; // day off by default
      }
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final schedule = _assignments.entries.map((e) => {
            'workDate': e.key,
            if (e.value != null) 'shiftNumber': e.value,
          }).toList();

      final api = ref.read(apiServiceProvider);
      await api.assignStaffShifts(widget.userId, schedule);

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift assignment saved successfully.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assign Weekly Shifts'),
                Text(widget.staffName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // Instruction
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select a shift or "Day Off" for each day. '
                        'Only one shift can be selected per day.',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),

              // Day rows
              ...List.generate(7, (i) {
                final date = now.add(Duration(days: i));
                final dateStr = _fmtDate(date);
                final current = _assignments[dateStr];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_dayLabel(date),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary)),
                                Text('${date.day}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: current,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: theme.colorScheme.primary, width: 2),
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Day Off'),
                                ),
                                ...widget.availableShifts.map((s) {
                                  final sNum = (s['shiftNumber'] as num).toInt();
                                  final sName = s['shiftName']?.toString() ?? '';
                                  final start = s['startTime']?.toString() ?? '';
                                  final end = s['endTime']?.toString() ?? '';
                                  final time = (start.isNotEmpty && end.isNotEmpty)
                                      ? '${_trimTime(start)} – ${_trimTime(end)}'
                                      : '';
                                  return DropdownMenuItem<int?>(
                                    value: sNum,
                                    child: Text(
                                        time.isNotEmpty ? '$sName  •  $time' : sName),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _assignments[dateStr] = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Shift Assignment'),
        ),
      ],
    );
  }

  String _trimTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
