import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String status; // ON_DUTY, OFF_DUTY, ON_LEAVE

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color dotColor;
    String text;

    switch (status.toUpperCase()) {
      case 'ON_DUTY':
        textColor = AppTheme.primary; // Or success green
        dotColor = AppTheme.success;
        text = 'On Duty';
        break;
      case 'OFF_DUTY':
        textColor = AppTheme.textSecondary;
        dotColor = AppTheme.divider;
        text = 'Off Duty';
        break;
      case 'ON_LEAVE':
        textColor = AppTheme.secondaryDark;
        dotColor = AppTheme.secondary;
        text = 'On Leave';
        break;
      default:
        textColor = AppTheme.textSecondary;
        dotColor = AppTheme.divider;
        text = status;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
