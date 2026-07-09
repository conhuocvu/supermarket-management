import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/widgets/shared/app_card.dart';

class ShiftOptionsList extends StatelessWidget {
  final List<Map<String, dynamic>> shiftTypes;
  final String selectedShiftType;
  final ValueChanged<String> onShiftTypeSelected;

  const ShiftOptionsList({
    super.key,
    required this.shiftTypes,
    required this.selectedShiftType,
    required this.onShiftTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final shift in shiftTypes) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            color: selectedShiftType == shift['type'] ? Colors.white : AppTheme.surface,
            border: Border.all(
              color: selectedShiftType == shift['type'] ? AppTheme.primary : AppTheme.border,
              width: selectedShiftType == shift['type'] ? 2 : 1,
            ),
            onTap: () => onShiftTypeSelected(shift['type'] as String),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: shift['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(shift['icon'] as IconData, color: shift['iconColor'] as Color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shift['time'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            shift['slots'] as String,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(shift['paceIcon'] as IconData, size: 14, color: shift['paceColor'] as Color),
                          const SizedBox(width: 4),
                          Text(
                            shift['pace'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: shift['paceColor'] as Color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selectedShiftType == shift['type'])
                  const Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
