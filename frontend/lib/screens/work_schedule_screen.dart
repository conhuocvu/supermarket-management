import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

class WorkScheduleScreen extends ConsumerStatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  ConsumerState<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends ConsumerState<WorkScheduleScreen> {
  late DateTime _visibleMonth;
  late Future<Map<int, Map<String, dynamic>>> _shiftsFuture;
  DateTime? _selectedDay;
  Map<int, Map<String, dynamic>> _shiftsCache = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    _shiftsFuture = _loadShifts();
  }

  Future<Map<int, Map<String, dynamic>>> _loadShifts() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      throw Exception('You must be signed in to view your schedule.');
    }
    final shifts = await ApiService()
        .fetchWorkSchedules(userId, _visibleMonth.year, _visibleMonth.month);
    final byDay = <int, Map<String, dynamic>>{};
    for (final s in shifts) {
      final date = DateTime.tryParse((s['workDate'] ?? '').toString());
      if (date != null) byDay[date.day] = s;
    }
    if (mounted) setState(() => _shiftsCache = Map.from(byDay));
    return byDay;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _shiftsCache = {};
      _shiftsFuture = _loadShifts();
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDay = now;
      _shiftsCache = {};
      _shiftsFuture = _loadShifts();
    });
  }

  void _selectDay(int dayNumber) {
    setState(() {
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final profile = ref.watch(authProvider).profile;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Work Schedule',
            breadcrumbs: ['Personal', 'Schedule'],
          );
    });

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Schedule',
            style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
        Text('View your assigned shifts and track monthly attendance.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _buildEmployeePeriodCard(context, profile),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1)),
              Text(DateFormat('MMMM yyyy').format(_visibleMonth),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1)),
            ]),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Jump to Today'),
              onPressed: _jumpToToday,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCalendarGrid(context),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: BentoCard(
              onTap: () => context.go('/leave-request'),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit_calendar,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Leave Request',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Request vacation or sick leave.',
                          style:
                              theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BentoCard(
              onTap: () => context.go('/schedule-change'),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.swap_horiz,
                      color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Schedule Change',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Swap shifts with colleagues.',
                          style:
                              theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ]),
            ),
          ),
        ]),
      ],
    );

    final sideContent = Column(children: [
      _buildShiftDetailsCard(context),
      const SizedBox(height: 16),
      _buildMonthlySummaryCard(context),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reminder: Overtime requests must be submitted at least 1 hour before shift end.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary, fontSize: 10),
            ),
          ),
        ]),
      ),
    ]);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: mainContent)),
              const SizedBox(width: 24),
              Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: sideContent)),
            ])
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(children: [
                mainContent,
                const SizedBox(height: 24),
                sideContent,
              ])),
    );
  }

  // ---------------------------------------------------------------------------
  // Employee / Period / Legend card
  // ---------------------------------------------------------------------------

  Widget _buildEmployeePeriodCard(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);
    final displayName = profile?.fullName ?? 'Employee';
    final userId = (profile?.userId ?? '') as String;
    final shortId = userId.length >= 8
        ? 'EMP-'
        : 'EMP-??????';

    return BentoCard(
      child: Row(children: [
        Expanded(
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.badge, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(shortId,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _buildLegendDot(Colors.green),
                const SizedBox(width: 6),
                Text('Completed', style: theme.textTheme.labelSmall),
                const SizedBox(width: 12),
                _buildLegendDot(theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Scheduled', style: theme.textTheme.labelSmall),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _buildLegendDot(theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Text('Late', style: theme.textTheme.labelSmall),
                const SizedBox(width: 24),
                _buildLegendDot(theme.colorScheme.error),
                const SizedBox(width: 6),
                Text('Absent', style: theme.textTheme.labelSmall),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _buildLegendDot(theme.colorScheme.outlineVariant),
                const SizedBox(width: 6),
                Text('Cancelled', style: theme.textTheme.labelSmall),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildLegendDot(Color color) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  // ---------------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------------

  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: weekdays
              .map((day) => Center(
                    child: Text(day,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ))
              .toList(),
        ),
        const Divider(height: 1),
        FutureBuilder<Map<int, Map<String, dynamic>>>(
          future: _shiftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(height: 8),
                  Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _shiftsFuture = _loadShifts()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ]),
              );
            }
            return _buildDaysGrid(context, snapshot.data ?? {});
          },
        ),
      ]),
    );
  }

  Widget _buildDaysGrid(
      BuildContext context, Map<int, Map<String, dynamic>> shiftsByDay) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final firstDay = _visibleMonth;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final prevMonthLast = DateTime(firstDay.year, firstDay.month, 0).day;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, childAspectRatio: 1.0),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayOffset = index - leading;
        final bool isOutsideMonth = dayOffset < 0 || dayOffset >= daysInMonth;
        final int dayNumber = dayOffset < 0
            ? prevMonthLast + dayOffset + 1
            : (dayOffset >= daysInMonth
                ? dayOffset - daysInMonth + 1
                : dayOffset + 1);

        final bool isToday = !isOutsideMonth &&
            firstDay.year == today.year &&
            firstDay.month == today.month &&
            dayNumber == today.day;

        final bool isSelected = !isOutsideMonth &&
            _selectedDay != null &&
            _visibleMonth.year == _selectedDay!.year &&
            _visibleMonth.month == _selectedDay!.month &&
            dayNumber == _selectedDay!.day;

        final shiftData = isOutsideMonth ? null : shiftsByDay[dayNumber];
        final shiftLabel = _shiftLabel(shiftData);
        final statusLabel = _statusLabel(shiftData);

        return GestureDetector(
          onTap: isOutsideMonth ? null : () => _selectDay(dayNumber),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : isToday
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                width: isSelected || isToday ? 2.0 : 0.5,
              ),
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : isToday
                      ? theme.colorScheme.primary.withValues(alpha: 0.03)
                      : null,
            ),
            child: Stack(children: [
              Positioned(
                top: 4,
                left: 6,
                child: Text('$dayNumber',
                    style: TextStyle(
                      color: isOutsideMonth
                          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                      fontWeight: (isToday || isSelected)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    )),
              ),
              if (isToday)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('TODAY',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              if (shiftLabel.isNotEmpty)
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_shiftAbbr(shiftLabel),
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer)),
                      ),
                      const SizedBox(height: 3),
                      if (statusLabel.isNotEmpty)
                        _buildLegendDot(_getStatusColor(statusLabel, theme)),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }

  String _shiftAbbr(String s) => s.length <= 5 ? s : s.substring(0, 4);

  // Full shift name from API field 'shiftName'
  String _shiftLabel(Map<String, dynamic>? d) {
    if (d == null) return '';
    return (d['shiftName'] ?? '').toString().trim();
  }

  // Human-readable status — maps all backend enum values (ASSIGNED/COMPLETED/MISSED/CANCELLED/LATE)
  String _statusLabel(Map<String, dynamic>? d) {
    switch ((d?['status'] ?? '').toString().toUpperCase()) {
      case 'COMPLETED': return 'Completed';
      case 'LATE':      return 'Late';
      case 'MISSED':    return 'Absent';
      case 'ASSIGNED':  return 'Scheduled';
      case 'CANCELLED': return 'Cancelled';
      default:          return '';
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'Late':      return theme.colorScheme.secondary;
      case 'Absent':    return theme.colorScheme.error;
      case 'Cancelled': return theme.colorScheme.outlineVariant;
      default:          return theme.colorScheme.primary;
    }
  }

  // ---------------------------------------------------------------------------
  // Shift Details Panel
  // ---------------------------------------------------------------------------

  Widget _buildShiftDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDay = _selectedDay;
    final inVisibleMonth = selectedDay != null &&
        selectedDay.year == _visibleMonth.year &&
        selectedDay.month == _visibleMonth.month;
    final shiftData =
        inVisibleMonth ? _shiftsCache[selectedDay.day] : null;

    final shiftName = (shiftData?['shiftName'] ?? '').toString().trim();
    final startTime = (shiftData?['startTime'] ?? '').toString();
    final endTime   = (shiftData?['endTime']   ?? '').toString();
    final status    = _statusLabel(shiftData);
    final dateLabel = selectedDay != null
        ? DateFormat('EEEE, MMM d').format(selectedDay)
        : 'Select a day';

    String fmtTime(String t) {
      if (t.isEmpty || t == 'null') return '--:--';
      return t.length >= 5 ? t.substring(0, 5) : t;
    }

    final startFmt = fmtTime(startTime);
    final endFmt   = fmtTime(endTime);

    String durationLabel = '';
    try {
      if (startFmt != '--:--' && endFmt != '--:--') {
        final sp = startFmt.split(':');
        final ep = endFmt.split(':');
        if (sp.length == 2 && ep.length == 2) {
          final sMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
          var   eMin = int.parse(ep[0]) * 60 + int.parse(ep[1]);
          if (eMin <= sMin) eMin += 24 * 60;
          final diff = eMin - sMin;
          final h = diff ~/ 60;
          final m = diff % 60;
          durationLabel = m == 0 ? '($h h)' : '($h h $m m)';
        }
      }
    } catch (_) {}

    return BentoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shift Details',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dateLabel,
                    style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (shiftName.isEmpty)
          Center(
            child: Column(children: [
              Icon(Icons.event_busy,
                  color: theme.colorScheme.onSurfaceVariant, size: 36),
              const SizedBox(height: 8),
              Text(
                selectedDay == null
                    ? 'Select a day to see shift details.'
                    : 'No shift assigned for this day.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ]),
          )
        else
          Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_shiftIcon(shiftName),
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shiftName,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('$startFmt - $endFmt $durationLabel'.trim(),
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ]),
            if (status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: theme.textTheme.bodySmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status, theme)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status, theme))),
                  ),
                ],
              ),
            ],
          ]),
      ]),
    );
  }

  IconData _shiftIcon(String s) {
    final l = s.toLowerCase();
    if (l.contains('morning') || l.contains('day')) {
      return Icons.wb_sunny;
    }
    if (l.contains('evening') || l.contains('night') ||
        l.contains('afternoon')) {
      return Icons.nights_stay;
    }
    return Icons.schedule;
  }

  // ---------------------------------------------------------------------------
  // Monthly Summary
  // ---------------------------------------------------------------------------

  Widget _buildMonthlySummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    int completed = 0, scheduled = 0, absent = 0, late = 0;
    for (final s in _shiftsCache.values) {
      final st = (s['status'] ?? '').toString().toUpperCase();
      if (st == 'COMPLETED') completed++;
      if (st == 'ASSIGNED')  scheduled++;
      if (st == 'MISSED')    absent++;
      if (st == 'LATE')      late++;
    }
    final total = _shiftsCache.length;

    return BentoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Monthly Summary',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(DateFormat('MMMM yyyy').format(_visibleMonth),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        _summaryRow(context, 'Total Shifts', '$total', theme.colorScheme.primary),
        const SizedBox(height: 8),
        _summaryRow(context, 'Completed',  '$completed', Colors.green),
        const SizedBox(height: 8),
        _summaryRow(context, 'Scheduled',  '$scheduled', theme.colorScheme.primary),
        const SizedBox(height: 8),
        _summaryRow(context, 'Late',       '$late',      theme.colorScheme.secondary),
        const SizedBox(height: 8),
        _summaryRow(context, 'Absent',     '$absent',    theme.colorScheme.error),
        const SizedBox(height: 16),
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed / total,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('${(completed / total * 100).toStringAsFixed(0)}% attendance rate',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ] else
          Text('No shifts assigned this month.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          _buildLegendDot(color),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ]),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
