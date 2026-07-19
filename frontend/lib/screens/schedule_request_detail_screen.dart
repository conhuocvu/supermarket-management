import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';
import 'request_detail_shared.dart';

/// UC 4.9 — View Schedule Change Detail.
/// Renders a single shift-change request from the raw API payload
/// (ShiftChangeRequestDTO: requestNumber, reason, status, createdDate,
/// approvedDate, current/target shift date-type-start-end) and lets the owner
/// cancel it while pending.
class ScheduleRequestDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const ScheduleRequestDetailScreen({super.key, required this.data});

  @override
  ConsumerState<ScheduleRequestDetailScreen> createState() =>
      _ScheduleRequestDetailScreenState();
}

class _ScheduleRequestDetailScreenState
    extends ConsumerState<ScheduleRequestDetailScreen> {
  bool _cancelling = false;

  Map<String, dynamic> get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final number = data['requestNumber'];
    final status = (data['status'] ?? 'PENDING').toString();
    final reason = (data['reason'] ?? '').toString();
    final isPending = status.toUpperCase() == 'PENDING';

    final currentType = (data['currentShiftType'] ?? '-').toString();
    final targetType = (data['targetShiftType'] ?? '-').toString();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Schedule Change Details',
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
            BentoCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.swap_horiz, color: theme.colorScheme.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule #${number ?? '-'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$currentType → $targetType',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Submitted: ${fmtDateTime(data['createdDate'])}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusBadge(status, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift Change Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  detailRow(context, 'Current Shift Type', currentType),
                  detailRow(context, 'Current Shift Date', fmtDate(data['currentShiftDate'])),
                  detailRow(context, 'Current Shift Hours',
                      _hours(data['currentShiftStart'], data['currentShiftEnd'])),
                  const Divider(),
                  detailRow(context, 'Target Shift Type', targetType),
                  detailRow(context, 'Target Shift Date', fmtDate(data['targetShiftDate'])),
                  detailRow(context, 'Target Shift Hours',
                      _hours(data['targetShiftStart'], data['targetShiftEnd'])),
                  const Divider(),
                  const SizedBox(height: 8),
                  reasonBox(context, reason),
                ],
              ),
            ),
            const SizedBox(height: 16),

            timelineCard(context, buildTimeline(data)),
            const SizedBox(height: 24),

            if (isPending)
              cancelButton(context, cancelling: _cancelling, onCancel: _cancel),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final userId = ref.read(authProvider).user?.id;
    final number = data['requestNumber'] as int?;
    if (userId == null || number == null) return;

    final confirmed = await confirmCancel(context, 'schedule change request');
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ApiService().cancelShiftChangeRequest(number, userId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showCancelError(context, e);
    }
  }

  String _hours(dynamic start, dynamic end) => '${fmtTime(start)} - ${fmtTime(end)}';
}
