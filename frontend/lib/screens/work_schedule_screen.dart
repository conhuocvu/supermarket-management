import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';
import 'leave_request_form.dart';
import 'schedule_request_form.dart';

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({Key? key}) : super(key: key);

  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  String currentDuration = '0h 15m';

  // Mock Calendar Days for June 2026
  final List<Map<String, dynamic>> calendarDays = [
    {'date': '31', 'isPrevMonth': true, 'shift': '', 'status': ''},
    {'date': '1', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Completed'},
    {'date': '2', 'isPrevMonth': false, 'shift': 'Afternoon', 'status': 'Late'},
    {'date': '3', 'isPrevMonth': false, 'shift': 'Day Off', 'status': ''},
    {'date': '4', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Scheduled', 'isToday': true},
    {'date': '5', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Absent'},
    {'date': '6', 'isPrevMonth': false, 'shift': 'Day Off', 'status': ''},
    {'date': '7', 'isPrevMonth': false, 'shift': '', 'status': ''},
    {'date': '8', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Scheduled'},
    {'date': '9', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Scheduled'},
    {'date': '10', 'isPrevMonth': false, 'shift': 'Day Off', 'status': ''},
    {'date': '11', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Scheduled'},
    {'date': '12', 'isPrevMonth': false, 'shift': 'Morning', 'status': 'Scheduled'},
    {'date': '13', 'isPrevMonth': false, 'shift': 'Day Off', 'status': ''},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    Widget mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Work Schedule',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          'Manage your shifts, view attendance records, and track monthly progress.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Info card (ID + Period + Legend)
        _buildEmployeePeriodCard(context, appState),
        const SizedBox(height: 16),

        // Calendar controller row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {},
                ),
                Text(
                  'June 2026',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {},
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Jump to Today'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Monthly calendar grid
        _buildCalendarGrid(context),
        const SizedBox(height: 16),

        // Bottom Bento actions
        Row(
          children: [
            Expanded(
              child: BentoCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LeaveRequestForm()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit_calendar, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Leave Request',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Request vacation or sick leave.',
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BentoCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ScheduleRequestForm()),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.swap_horiz, color: theme.colorScheme.secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Schedule Change',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Swap shifts with colleagues.',
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );

    Widget sideContent = Column(
      children: [
        // Shift Details Card
        _buildShiftDetailsCard(context),
        const SizedBox(height: 16),

        // Attendance Tracking Card
        _buildAttendanceTrackingCard(context),
        const SizedBox(height: 16),

        // Overtime reminder
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reminder: Overtime requests must be submitted at least 1 hour before shift end.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: mainContent,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: sideContent,
            ),
          ),
        ],
      );
    } else {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            mainContent,
            const SizedBox(height: 24),
            sideContent,
          ],
        ),
      );
    }
  }

  Widget _buildEmployeePeriodCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Row(
        children: [
          // Left: ID & Period
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.badge, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EMPLOYEE ID', style: theme.textTheme.labelSmall),
                    Text(
                      'EMP-82910',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE PERIOD', style: theme.textTheme.labelSmall),
                    Text(
                      'June 2026',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: Legend
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLegendDot(Colors.green),
                    const SizedBox(width: 6),
                    Text('Completed', style: theme.textTheme.labelSmall),
                    const SizedBox(width: 12),
                    _buildLegendDot(theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('Scheduled', style: theme.textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildLegendDot(theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text('Late', style: theme.textTheme.labelSmall),
                    const SizedBox(width: 48),
                    _buildLegendDot(theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Text('Absent', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Weekday headers
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: weekdays.map((day) {
              return Center(
                child: Text(
                  day,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 1),
          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              final bool isPrevMonth = day['isPrevMonth'];
              final bool isToday = day['isToday'] ?? false;
              final String shift = day['shift'];
              final String status = day['status'];

              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withOpacity(0.15),
                    width: isToday ? 2.0 : 0.5,
                  ),
                  color: isToday ? theme.colorScheme.primary.withOpacity(0.03) : null,
                ),
                child: Stack(
                  children: [
                    // Day number
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Text(
                        day['date'],
                        style: TextStyle(
                          color: isPrevMonth
                              ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                              : theme.colorScheme.onSurface,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Today banner badge
                    if (isToday)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Shift Badge & Status Dot
                    if (shift.isNotEmpty)
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: shift == 'Day Off'
                                    ? theme.colorScheme.primary.withOpacity(0.1)
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shift,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: shift == 'Day Off'
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (status.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendDot(_getStatusColor(status, theme)),
                                  const SizedBox(width: 4),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status, theme),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    if (status == 'Completed') return Colors.green;
    if (status == 'Late') return theme.colorScheme.secondary;
    if (status == 'Absent') return theme.colorScheme.error;
    return theme.colorScheme.primary;
  }

  Widget _buildShiftDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Thursday, June 4',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.nights_stay, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evening Shift',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('16:00 - 00:00 (8h)', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Department', style: theme.textTheme.bodySmall),
              Text(
                'Produce & Fresh',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Supervisor', style: theme.textTheme.bodySmall),
              Text(
                'Elena Petrov',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTrackingCard(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Tracking',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHECK IN', style: theme.textTheme.labelSmall),
                      Text(
                        appState.checkInTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CHECK OUT', style: theme.textTheme.labelSmall),
                      Text(
                        appState.checkOutTime,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(appState.isCheckedIn ? Icons.logout : Icons.login),
              label: Text(appState.isCheckedIn ? 'Check-Out' : 'Check-In Now'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                appState.toggleCheckIn();
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Duration', style: theme.textTheme.bodySmall),
              Text(
                appState.isCheckedIn ? 'Running...' : currentDuration,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
