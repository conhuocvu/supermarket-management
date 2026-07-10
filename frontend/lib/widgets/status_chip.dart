import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final String type;

  const StatusChip({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type.toUpperCase()) {
      case 'ACTIVE':
      case 'SUCCESS':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case 'WARNING':
      case 'LOW_STOCK':
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.error;
        icon = Icons.warning_amber_rounded;
        break;
      case 'INACTIVE':
      case 'ERROR':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        icon = Icons.cancel_outlined;
        break;
      case 'INFO':
      default:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
