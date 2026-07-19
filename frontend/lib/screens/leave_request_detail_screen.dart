import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';
import 'request_detail_shared.dart';

/// UC 4.8 — View Leave Request Detail.
/// Renders a single leave request from the raw API payload
/// (LeaveRequestDTO: leaveNumber, reason, startDate, endDate, status,
/// createdDate, approvedDate) and lets the owner cancel it while pending.
class LeaveRequestDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const LeaveRequestDetailScreen({super.key, required this.data});

  @override
  ConsumerState<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState
    extends ConsumerState<LeaveRequestDetailScreen> {
  bool _cancelling = false;

  Map<String, dynamic> get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final number = data['leaveNumber'];
    final status = (data['status'] ?? 'PENDING').toString();
    final reason = (data['reason'] ?? '').toString();
    final startDate = data['startDate']?.toString();
    final endDate = data['endDate']?.toString();
    final isPending = status.toUpperCase() == 'PENDING';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
            BentoCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.time_to_leave, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave #${number ?? '-'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reason.isNotEmpty ? reason : 'Leave request',
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
                    'Leave Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  detailRow(context, 'Start Date', fmtDate(startDate)),
                  const Divider(),
                  detailRow(context, 'End Date', fmtDate(endDate)),
                  const Divider(),
                  detailRow(context, 'Duration', _duration(startDate, endDate)),
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
              cancelButton(
                context,
                cancelling: _cancelling,
                onCancel: _cancel,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final userId = ref.read(authProvider).user?.id;
    final number = data['leaveNumber'] as int?;
    if (userId == null || number == null) return;

    final confirmed = await confirmCancel(context, 'leave request');
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ApiService().cancelLeaveRequest(number, userId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showCancelError(context, e);
    }
  }

  String _duration(String? start, String? end) {
    final s = DateTime.tryParse(start ?? '');
    final e = DateTime.tryParse(end ?? '');
    if (s == null || e == null) return '-';
    final days = e.difference(s).inDays + 1;
    return days == 1 ? '1 day' : '$days days';
  }
}
