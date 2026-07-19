import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import 'bento_card.dart';

class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({super.key});

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  bool _attendanceActionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        ref.read(attendanceProvider.notifier).loadTodayAttendance(userId);
      }
    });
  }

  Future<void> _handleAttendanceAction(ThemeData theme, bool isCheckedIn) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || _attendanceActionInProgress) return;

    setState(() => _attendanceActionInProgress = true);
    try {
      if (isCheckedIn) {
        await ref.read(attendanceProvider.notifier).checkOut(userId);
      } else {
        await ref.read(attendanceProvider.notifier).checkIn(userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckedIn
                ? 'Successfully Checked-Out of Shift!'
                : 'Successfully Checked-In to Shift!',
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor:
              isCheckedIn ? theme.colorScheme.primary : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      ref.read(attendanceProvider.notifier).loadTodayAttendance(userId);
    } finally {
      if (mounted) {
        setState(() => _attendanceActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(attendanceProvider);

    final attendance = attendanceAsync.valueOrNull;
    final isLoading = attendanceAsync.isLoading;
    final isCheckedIn = attendance?.isCheckedIn ?? false;
    final checkInTime = attendance?.checkInTime != null
        ? DateFormat('hh:mm a').format(attendance!.checkInTime!.toLocal())
        : '--:--';
    final checkOutTime = attendance?.checkOutTime != null
        ? DateFormat('hh:mm a').format(attendance!.checkOutTime!.toLocal())
        : '--:--';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Attendance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? Colors.green.withValues(alpha: 0.1)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCheckedIn
                        ? Colors.green.withValues(alpha: 0.3)
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color: isCheckedIn ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCheckedIn ? 'ON DUTY' : 'OFF DUTY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCheckedIn ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeBox(context, 'CHECK-IN TIME', checkInTime,
                    highlight: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _buildTimeBox(context, 'CHECK-OUT TIME', checkOutTime),
              ),
            ],
          ),
          if (attendanceAsync.hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Could not load attendance. Pull to refresh or try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _attendanceActionInProgress || isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Icon(isCheckedIn ? Icons.logout : Icons.login),
              label: Text(isCheckedIn ? 'Check-Out Shift' : 'Check-In Now'),
              style: FilledButton.styleFrom(
                backgroundColor: isCheckedIn
                    ? theme.colorScheme.error.withValues(alpha: 0.9)
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _attendanceActionInProgress || isLoading
                  ? null
                  : () => _handleAttendanceAction(theme, isCheckedIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
