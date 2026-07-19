import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';
import 'leave_request_detail_screen.dart';
import 'schedule_request_detail_screen.dart';

class ManageRequestStatusScreen extends ConsumerStatefulWidget {
  const ManageRequestStatusScreen({super.key});

  @override
  ConsumerState<ManageRequestStatusScreen> createState() =>
      _ManageRequestStatusScreenState();
}

/// A leave or schedule-change request rendered in the combined list.
class _UserRequest {
  final bool isLeave;
  final int? number;
  final String status;
  final String title;
  final String subtitle;
  final DateTime? createdDate;
  final Map<String, dynamic> raw;

  _UserRequest({
    required this.isLeave,
    required this.number,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.createdDate,
    required this.raw,
  });
}

class _ManageRequestStatusScreenState
    extends ConsumerState<ManageRequestStatusScreen> {
  late Future<List<_UserRequest>> _future;
  int? _cancellingIndex;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_UserRequest>> _load() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) {
      throw Exception('You must be signed in to view your requests.');
    }
    final api = ApiService();
    final results = await Future.wait([
      api.fetchLeaveRequests(userId),
      api.fetchShiftChangeRequests(userId),
    ]);

    final requests = <_UserRequest>[
      for (final r in results[0])
        _UserRequest(
          isLeave: true,
          number: r['leaveNumber'] as int?,
          status: (r['status'] ?? 'PENDING').toString(),
          title: (r['reason'] ?? 'Leave request').toString(),
          subtitle: '${_fmtDate(r['startDate'])}  →  ${_fmtDate(r['endDate'])}',
          createdDate: DateTime.tryParse((r['createdDate'] ?? '').toString()),
          raw: r,
        ),
      for (final r in results[1])
        _UserRequest(
          isLeave: false,
          number: r['requestNumber'] as int?,
          status: (r['status'] ?? 'PENDING').toString(),
          title: _buildShiftChangeTitle(r),
          subtitle: _buildShiftChangeSubtitle(r),
          createdDate: DateTime.tryParse((r['createdDate'] ?? '').toString()),
          raw: r,
        ),
    ];

    requests.sort((a, b) {
      final ad = a.createdDate, bd = b.createdDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return requests;
  }

  void _refresh() => setState(() => _future = _load());

  /// UC 4.8 / 4.9 — open the detail screen; refresh the list when the
  /// request was cancelled from within the detail view.
  Future<void> _openDetail(_UserRequest r) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => r.isLeave
            ? LeaveRequestDetailScreen(data: r.raw)
            : ScheduleRequestDetailScreen(data: r.raw),
      ),
    );
    if (changed == true && mounted) _refresh();
  }

  Future<void> _cancel(_UserRequest r, int index) async {
    final userId = ref.read(authProvider).user?.id;
    final number = r.number;
    if (userId == null || number == null) return;

    final label = r.isLeave ? 'leave request' : 'schedule change request';
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true) return;

    setState(() => _cancellingIndex = index);
    try {
      if (r.isLeave) {
        await ApiService().cancelLeaveRequest(number, userId);
      } else {
        await ApiService().cancelShiftChangeRequest(number, userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request cancelled.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancellingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Manage Request Status',
            breadcrumbs: ['Personal', 'Request Status'],
          );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<List<_UserRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _messageCard(
              context,
              Icons.error_outline,
              'Could not load requests',
              snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _refresh,
            );
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return _messageCard(
              context,
              Icons.rule_folder_outlined,
              'No requests yet',
              'Submitted leave and schedule change requests will appear here so you can track and cancel them.',
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _requestTile(context, theme, requests[i], i),
            ),
          );
        },
      ),
    );
  }

  Widget _requestTile(BuildContext context, ThemeData theme, _UserRequest r, int index) {
    final isPending = r.status.toUpperCase() == 'PENDING';

    return BentoCard(
      onTap: () => _openDetail(r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              r.isLeave ? Icons.time_to_leave : Icons.swap_horiz,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${r.isLeave ? 'Leave' : 'Schedule'} #${r.number ?? '-'}',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(r.status, theme),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  r.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            _cancellingIndex == index
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: r.number == null ? null : () => _cancel(r, index),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, ThemeData theme) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        upper.isEmpty ? 'PENDING' : upper,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _messageCard(BuildContext context, IconData icon, String title, String body,
      {VoidCallback? onRetry}) {
    final theme = Theme.of(context);
    return Center(
      child: BentoCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(dynamic iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso.toString());
    return d == null ? iso.toString() : DateFormat('MMM dd, yyyy').format(d);
  }

  /// Builds a descriptive title for a shift change request using structured columns.
  static String _buildShiftChangeTitle(Map<String, dynamic> r) {
    final currentType = r['currentShiftType'] as String?;
    final targetType = r['targetShiftType'] as String?;
    if (currentType != null && targetType != null) {
      return '$currentType → $targetType';
    }
    // Fallback: reason or generic label
    final reason = r['reason'] as String?;
    return reason?.isNotEmpty == true ? reason! : 'Shift Change Request';
  }

  /// Builds a subtitle showing the current and target shift dates.
  static String _buildShiftChangeSubtitle(Map<String, dynamic> r) {
    final currentDate = r['currentShiftDate'] as String?;
    final targetDate = r['targetShiftDate'] as String?;
    final currentStart = r['currentShiftStart'] as String?;
    final currentEnd = r['currentShiftEnd'] as String?;
    final targetStart = r['targetShiftStart'] as String?;
    final targetEnd = r['targetShiftEnd'] as String?;

    if (currentDate != null && targetDate != null) {
      final cLabel = _fmtShortDate(currentDate);
      final tLabel = _fmtShortDate(targetDate);
      final cTime = (currentStart != null && currentEnd != null)
          ? ' (${currentStart.substring(0, 5)}-${currentEnd.substring(0, 5)})'
          : '';
      final tTime = (targetStart != null && targetEnd != null)
          ? ' (${targetStart.substring(0, 5)}-${targetEnd.substring(0, 5)})'
          : '';
      return '$cLabel$cTime  →  $tLabel$tTime';
    }
    return 'Submitted ${_fmtDate(r['createdDate'])}';
  }

  static String _fmtShortDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd/MM/yyyy').format(d);
  }
}
