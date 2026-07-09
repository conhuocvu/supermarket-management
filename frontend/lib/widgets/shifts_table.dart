import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/shift.dart';
import 'package:frontend/widgets/shared/app_card.dart';

class ShiftsTable extends StatelessWidget {
  final List<Shift> recentShifts;

  const ShiftsTable({super.key, required this.recentShifts});

  @override
  Widget build(BuildContext context) {
    if (recentShifts.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa có ca làm việc nào gần đây.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DURATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final shift in recentShifts.take(3))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMM d, yyyy').format(shift.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${shift.startTime} - ${shift.endTime}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      shift.register ?? 'Floor / Stock',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
