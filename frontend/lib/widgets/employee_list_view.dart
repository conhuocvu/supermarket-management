import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/providers/employee_provider.dart';
import 'package:frontend/widgets/shared/app_card.dart';
import 'package:frontend/widgets/shared/empty_view.dart';
import 'package:frontend/widgets/shared/error_view.dart';
import 'package:frontend/widgets/shared/loading_view.dart';
import 'package:frontend/widgets/shared/status_chip.dart';
import 'package:frontend/widgets/shared/user_avatar.dart';
import 'package:frontend/core/errors/app_error.dart';

class EmployeeListView extends ConsumerWidget {
  const EmployeeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return employeesAsync.when(
      data: (employees) {
        if (employees.isEmpty) {
          return const EmptyView(
            title: 'No employees found',
            description: 'Try searching with a different name or changing the status filter.',
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: employees.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final emp = employees[index];
            String shiftText = '';
            if (emp.status == 'ON_LEAVE' && emp.returnsDate != null) {
              final formatted = '${emp.returnsDate!.day}/${emp.returnsDate!.month}';
              shiftText = 'RETURNS: $formatted';
            } else if (emp.recentShifts.isNotEmpty) {
              final latest = emp.recentShifts.first;
              final prefix = latest.completed ? 'SHIFT' : 'NEXT SHIFT';
              shiftText = '$prefix: ${latest.startTime} - ${latest.endTime}';
            } else {
              shiftText = 'NO SHIFTS SCHEDULED';
            }

            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () => context.push('/profile/${emp.id}'),
              child: Row(
                children: [
                  UserAvatar(
                    name: emp.name,
                    imageUrl: emp.imageUrl,
                    radius: 28,
                    status: emp.status,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              emp.role.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.fiber_manual_record, size: 6, color: AppTheme.divider),
                            const SizedBox(width: 6),
                            StatusChip(status: emp.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shiftText.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(
        isFullScreen: false,
        message: 'Loading employees list...',
      ),
      error: (err, stack) {
        final message = err is AppError
            ? err.userMessage
            : 'Failed to load employees list. Please check backend connection.';
        return ErrorView(
          message: message,
          onRetry: () {
            ref.invalidate(employeesProvider);
            ref.invalidate(employeeStatsProvider);
          },
        );
      },
    );
  }
}
