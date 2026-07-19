import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/bento_card.dart';

/// Shared UI + formatting helpers for the leave (UC 4.8) and schedule-change
/// (UC 4.9) detail screens. Both render raw API payloads, so the timeline is
/// derived from the createdDate/approvedDate/status fields the DTOs expose.

class RequestTimelineEvent {
  final String title;
  final String description;
  final DateTime? timestamp;
  RequestTimelineEvent(this.title, this.description, this.timestamp);
}

String fmtDate(dynamic iso) {
  if (iso == null || iso.toString().isEmpty) return '-';
  final d = DateTime.tryParse(iso.toString());
  return d == null ? iso.toString() : DateFormat('MMM dd, yyyy').format(d);
}

String fmtDateTime(dynamic iso) {
  if (iso == null || iso.toString().isEmpty) return '-';
  final d = DateTime.tryParse(iso.toString());
  return d == null ? iso.toString() : DateFormat('MMM dd, yyyy - hh:mm a').format(d);
}

/// hh:mm from an ISO time/date-time string ("14:30:00" -> "14:30").
String fmtTime(dynamic iso) {
  final s = iso?.toString() ?? '';
  if (s.isEmpty) return '-';
  final t = DateTime.tryParse('2000-01-01T$s');
  if (t != null) return DateFormat('HH:mm').format(t);
  return s.length >= 5 ? s.substring(0, 5) : s;
}

/// Builds a lifecycle timeline from the fields every request DTO carries.
List<RequestTimelineEvent> buildTimeline(Map<String, dynamic> data) {
  final status = (data['status'] ?? 'PENDING').toString().toUpperCase();
  final created = DateTime.tryParse((data['createdDate'] ?? '').toString());
  final approved = DateTime.tryParse((data['approvedDate'] ?? '').toString());

  final events = <RequestTimelineEvent>[
    RequestTimelineEvent('Request Submitted', 'Sent for manager review', created),
  ];

  switch (status) {
    case 'APPROVED':
    case 'RESOLVED':
      events.add(RequestTimelineEvent('Request Approved', 'Approved by manager', approved));
      break;
    case 'REJECTED':
      events.add(RequestTimelineEvent('Request Rejected', 'Rejected by manager', approved));
      break;
    case 'CANCELLED':
      events.add(RequestTimelineEvent('Request Cancelled', 'Cancelled by you', approved));
      break;
    default:
      events.add(RequestTimelineEvent('Awaiting Review', 'Pending approval by manager', null));
  }
  return events;
}

Widget statusBadge(String status, ThemeData theme) {
  final upper = status.toUpperCase();
  Color color;
  switch (upper) {
    case 'APPROVED':
    case 'RESOLVED':
      color = theme.colorScheme.primary;
      break;
    case 'REJECTED':
    case 'CANCELLED':
      color = theme.colorScheme.error;
      break;
    default:
      color = theme.colorScheme.secondary;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      upper.isEmpty ? 'PENDING' : upper,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

Widget detailRow(BuildContext context, String label, String value) {
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
        Flexible(
          child: Text(
            value.isNotEmpty ? value : '-',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

Widget reasonBox(BuildContext context, String reason) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          reason.isNotEmpty ? reason : 'No reason provided.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

Widget timelineCard(BuildContext context, List<RequestTimelineEvent> events) {
  final theme = Theme.of(context);
  return BentoCard(
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
        for (int i = 0; i < events.length; i++)
          _timelineItem(context, events[i], i == 0, i == events.length - 1),
      ],
    ),
  );
}

Widget _timelineItem(BuildContext context, RequestTimelineEvent event, bool isFirst, bool isLast) {
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
            Container(width: 2, height: 48, color: theme.colorScheme.outlineVariant),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.timestamp == null
                  ? 'Pending'
                  : DateFormat('MMM dd, yyyy - hh:mm a').format(event.timestamp!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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

Widget cancelButton(BuildContext context,
    {required bool cancelling, required VoidCallback onCancel}) {
  final theme = Theme.of(context);
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: theme.colorScheme.error),
      ),
      onPressed: cancelling ? null : onCancel,
      child: cancelling
          ? const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              'Cancel Request',
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
    ),
  );
}

Future<bool?> confirmCancel(BuildContext context, String label) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Cancel $label?'),
      content: const Text('Your pending request will be marked as cancelled.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancel Request'),
        ),
      ],
    ),
  );
}

void showCancelError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed to cancel: ${e.toString().replaceFirst('Exception: ', '')}'),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

