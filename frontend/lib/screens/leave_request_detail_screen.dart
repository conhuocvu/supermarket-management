import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final RequestItem request;

  const LeaveRequestDetailScreen({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final leaveType = request.details['leaveType'] ?? 'Vacation';
    final startDate = request.details['startDate'] ?? '';
    final endDate = request.details['endDate'] ?? '';
    final reason = request.details['reason'] ?? '';
    final approvedBy = request.details['approvedBy'] ?? 'N/A';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Leave Request Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Header Bento Card
            BentoCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.time_to_leave,
                      color: Color(0xFF00503E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.id,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Submitted: ${DateFormat('MMM dd, yyyy').format(request.submissionDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Specifications Bento Card
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Leave Type', leaveType),
                  const Divider(),
                  _buildDetailRow(context, 'Start Date', startDate),
                  const Divider(),
                  _buildDetailRow(context, 'End Date', endDate),
                  const Divider(),
                  _buildDetailRow(context, 'Approved By', approvedBy),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Reason:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reason,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline / History Bento Card
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Lifecycle Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: request.timeline.length,
                    itemBuilder: (context, index) {
                      final event = request.timeline[index];
                      final isFirst = index == 0;
                      final isLast = index == request.timeline.length - 1;
                      return _buildTimelineItem(context, event, isFirst, isLast);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Manager Approval Actions
            if (appState.currentUser.role == UserRole.manager && request.status == RequestStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      onPressed: () {
                        // Reject request
                        _updateRequestStatus(context, appState, RequestStatus.rejected);
                      },
                      child: Text(
                        'Reject Request',
                        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Approve request
                        _updateRequestStatus(context, appState, RequestStatus.approved);
                      },
                      child: const Text(
                        'Approve Request',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _updateRequestStatus(BuildContext context, AppState appState, RequestStatus status) {
    // Find request in appState list and update status
    final index = appState.requests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      final updatedRequest = appState.requests[index].copyWith(
        status: status,
        timeline: [
          ...appState.requests[index].timeline,
          TimelineEvent(
            title: status == RequestStatus.approved ? 'Approved by Manager' : 'Rejected by Manager',
            description: status == RequestStatus.approved
                ? 'Approved by ${appState.currentUser.name}'
                : 'Rejected by ${appState.currentUser.name}',
            timestamp: DateTime.now(),
          )
        ],
      );
      appState.updateRequest(updatedRequest);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request has been ${status == RequestStatus.approved ? "Approved" : "Rejected"}'),
          backgroundColor: status == RequestStatus.approved ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value.isNotEmpty ? value : 'Pending Approval',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: value.isNotEmpty ? theme.colorScheme.onSurface : theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status, ThemeData theme) {
    Color badgeColor;
    String label;

    switch (status) {
      case RequestStatus.pending:
        badgeColor = theme.colorScheme.secondary;
        label = 'Pending';
        break;
      case RequestStatus.approved:
        badgeColor = theme.colorScheme.primary;
        label = 'Approved';
        break;
      case RequestStatus.rejected:
        badgeColor = theme.colorScheme.error;
        label = 'Rejected';
        break;
      case RequestStatus.resolved:
        badgeColor = theme.colorScheme.primary;
        label = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEvent event, bool isFirst, bool isLast) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? theme.colorScheme.primary : theme.colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                event.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(event.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
