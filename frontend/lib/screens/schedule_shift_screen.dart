import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_button.dart';
import 'package:frontend/widgets/shared/app_card.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/page_container.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/widgets/date_selector.dart';
import 'package:frontend/widgets/shift_options_list.dart';
import 'package:frontend/core/errors/app_error.dart';

class ScheduleShiftScreen extends ConsumerStatefulWidget {
  final int employeeId;

  const ScheduleShiftScreen({super.key, required this.employeeId});

  @override
  ConsumerState<ScheduleShiftScreen> createState() => _ScheduleShiftScreenState();
}

class _ScheduleShiftScreenState extends ConsumerState<ScheduleShiftScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedShiftType = 'AFTERNOON';
  bool _submitting = false;

  final List<DateTime> _dates = List.generate(5, (index) => DateTime.now().add(Duration(days: index)));

  final List<Map<String, dynamic>> _shiftTypes = [
    {
      'type': 'MORNING',
      'title': 'Morning Shift',
      'time': '06:00 - 14:00',
      'startTime': '06:00',
      'endTime': '14:00',
      'icon': Icons.wb_sunny_outlined,
      'iconColor': const Color(0xFFF59E0B),
      'bgColor': const Color(0xFFFEF3C7),
      'slots': '4/6 Slots',
      'pace': 'High Traffic',
      'paceIcon': Icons.trending_up,
      'paceColor': AppTheme.primary,
    },
    {
      'type': 'AFTERNOON',
      'title': 'Afternoon Shift',
      'time': '14:00 - 22:00',
      'startTime': '14:00',
      'endTime': '22:00',
      'icon': Icons.wb_twilight,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
      'slots': '2/6 Slots',
      'pace': 'Standard Pace',
      'paceIcon': Icons.info_outline,
      'paceColor': AppTheme.textSecondary,
    },
    {
      'type': 'EVENING',
      'title': 'Evening Shift',
      'time': '22:00 - 06:00',
      'startTime': '22:00',
      'endTime': '06:00',
      'icon': Icons.nightlight_outlined,
      'iconColor': const Color(0xFF6366F1),
      'bgColor': const Color(0xFFE0E7FF),
      'slots': '1/3 Slots',
      'pace': 'Night Premium',
      'paceIcon': Icons.bolt,
      'paceColor': const Color(0xFFD97706),
    },
  ];

  Future<void> _confirmAssignment(String employeeName) async {
    setState(() => _submitting = true);

    final shiftDetails = _shiftTypes.firstWhere((e) => e['type'] == _selectedShiftType);

    final result = await ref.read(employeesProvider.notifier).assignShift(
          widget.employeeId,
          date: _selectedDate,
          startTime: shiftDetails['startTime'] as String,
          endTime: shiftDetails['endTime'] as String,
          shiftType: _selectedShiftType,
          register: _selectedShiftType == 'MORNING'
              ? 'Register 04'
              : (_selectedShiftType == 'AFTERNOON' ? 'Register 02' : null),
        );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (result.isSuccess) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Shift assigned successfully!'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error?.userMessage ?? 'Failed to assign shift.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeAsync = ref.watch(employeeDetailProvider(widget.employeeId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Schedule Shift',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: UserAvatar(
              name: "David Okafor",
              imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
              radius: 18,
            ),
          ),
        ],
      ),
      body: employeeAsync.when(
        data: (emp) => PageContainer(
          child: ListView(
            children: [
              const SizedBox(height: 16),

              // Employee Profile Header
              AppCard(
                child: Row(
                  children: [
                    UserAvatar(name: emp.name, imageUrl: emp.imageUrl, radius: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(168, 213, 194, 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  emp.role.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: AppTheme.primaryDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              const Text(
                                '32h / 40h',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 24),

              // Select Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Date Selector
              DateSelector(
                dates: _dates,
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 24),

              Text(
                'Available Shifts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Shift cards
              ShiftOptionsList(
                shiftTypes: _shiftTypes,
                selectedShiftType: _selectedShiftType,
                onShiftTypeSelected: (type) => setState(() => _selectedShiftType = type),
              ),

              const SizedBox(height: 32),
              AppButton(
                text: 'Confirm Assignment',
                icon: Icons.calendar_today_outlined,
                isLoading: _submitting,
                onPressed: () => _confirmAssignment(emp.name),
              ),
              const SizedBox(height: 12),
              Text(
                "Assigning this shift will update ${emp.name}'s schedule and notify them via the team app.",
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const LoadingView(message: 'Đang tải thông tin nhân viên...'),
        error: (err, stack) {
          final message = err is AppError ? err.userMessage : 'Không thể tải chi tiết nhân viên. Vui lòng thử lại.';
          return ErrorView(
            message: message,
            onRetry: () => ref.invalidate(employeeDetailProvider(widget.employeeId)),
          );
        },
      ),
    );
  }
}
