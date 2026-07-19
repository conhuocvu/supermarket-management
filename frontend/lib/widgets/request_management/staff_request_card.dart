import 'package:flutter/material.dart';

import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';
import 'request_action_buttons.dart';
import 'request_chips.dart';
import 'request_management_formatters.dart';

class StaffRequestCard extends StatelessWidget {
  final StaffRequest request;
  final StaffRequestState state;
  final Future<void> Function(StaffRequest, String) onUpdateStatus;

  const StaffRequestCard({
    super.key,
    required this.request,
    required this.state,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  employeeInitial(request.employeeName),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request #${request.requestNumber}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              RequestStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 16),
          RequestTypeChip(request: request),
          const SizedBox(height: 14),
          Text(
            requestDetails(request),
            style: TextStyle(color: colorScheme.onSurface, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                formatRequestDateTime(request.createdDate),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (request.status.toUpperCase() == 'PENDING') ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: RequestActionButtons(
                request: request,
                state: state,
                compact: true,
                onUpdateStatus: onUpdateStatus,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
