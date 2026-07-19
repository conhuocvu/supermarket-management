import 'package:flutter/material.dart';

import '../../models/staff_request.dart';

class RequestTypeChip extends StatelessWidget {
  final StaffRequest request;

  const RequestTypeChip({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLeave = request.isLeaveRequest;
    final backgroundColor = isLeave
        ? colorScheme.secondaryContainer
        : colorScheme.tertiaryContainer;
    final textColor = isLeave
        ? colorScheme.onSecondaryContainer
        : colorScheme.onTertiaryContainer;
    final icon = isLeave
        ? Icons.event_available_rounded
        : Icons.swap_horiz_rounded;

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            request.requestTypeLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestStatusChip extends StatelessWidget {
  final String status;

  const RequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = status.toUpperCase();

    late final Color backgroundColor;
    late final Color textColor;

    switch (normalized) {
      case 'APPROVED':
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        break;
      case 'REJECTED':
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        break;
      case 'PENDING':
        backgroundColor = colorScheme.tertiaryContainer;
        textColor = colorScheme.onTertiaryContainer;
        break;
      default:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
    }

    final label = normalized.isEmpty
        ? 'Unknown'
        : normalized[0] + normalized.substring(1).toLowerCase();

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
