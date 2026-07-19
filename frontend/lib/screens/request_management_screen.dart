import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_request.dart';
import '../providers/staff_request_provider.dart';

class RequestManagementScreen extends ConsumerStatefulWidget {
  const RequestManagementScreen({super.key});

  @override
  ConsumerState<RequestManagementScreen> createState() =>
      _RequestManagementScreenState();
}

class _RequestManagementScreenState
    extends ConsumerState<RequestManagementScreen> {
  static const Color _primary = Color(0xFF00503E);
  static const Color _background = Color(0xFFF8F9FF);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE1E7E5);
  static const Color _textPrimary = Color(0xFF17201D);
  static const Color _textSecondary = Color(0xFF66736F);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffRequestProvider);
    final notifier = ref.read(staffRequestProvider.notifier);

    return ColoredBox(
      color: _background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, state, notifier, isCompact),
                  const SizedBox(height: 20),
                  _buildFilterPanel(state, notifier),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(state.errorMessage!, notifier),
                  ],
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent(state, notifier, isCompact)),
                  const SizedBox(height: 16),
                  _buildPagination(state, notifier),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StaffRequestState state,
    StaffRequestNotifier notifier,
    bool isCompact,
  ) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Management',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review leave and shift change requests submitted by staff.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _textSecondary),
        ),
      ],
    );

    final refreshButton = SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: state.isLoading ? null : notifier.refresh,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleSection, const SizedBox(height: 16), refreshButton],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 24),
        refreshButton,
      ],
    );
  }

  Widget _buildFilterPanel(
    StaffRequestState state,
    StaffRequestNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: notifier.updateKeyword,
            decoration: InputDecoration(
              hintText: 'Search by employee name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        notifier.updateKeyword('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: _background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterGroup(
            title: 'Request type',
            values: const {
              'ALL': 'All',
              'LEAVE': 'Leave',
              'SHIFT_CHANGE': 'Shift Change',
            },
            selectedValue: state.requestType,
            onSelected: notifier.updateRequestType,
          ),
          const SizedBox(height: 16),
          _buildFilterGroup(
            title: 'Status',
            values: const {
              'ALL': 'All',
              'PENDING': 'Pending',
              'APPROVED': 'Approved',
              'REJECTED': 'Rejected',
            },
            selectedValue: state.status,
            onSelected: notifier.updateStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    required Map<String, String> values,
    required String selectedValue,
    required Future<void> Function(String value) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.entries.map((entry) {
            final selected = selectedValue == entry.key;

            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onSelected(entry.key),
              showCheckmark: false,
              selectedColor: _primary,
              backgroundColor: _background,
              side: BorderSide(color: selected ? _primary : _border),
              labelStyle: TextStyle(
                color: selected ? Colors.white : _textSecondary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, StaffRequestNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC9C4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7A271A)),
            ),
          ),
          TextButton(onPressed: notifier.refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(
    StaffRequestState state,
    StaffRequestNotifier notifier,
    bool isCompact,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (state.items.isEmpty) {
      return _buildEmptyState();
    }

    if (isCompact) {
      return RefreshIndicator(
        color: _primary,
        onRefresh: notifier.refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildRequestCard(state.items[index], state, notifier);
          },
        ),
      );
    }

    return _buildDesktopTable(state, notifier);
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: _textSecondary),
              SizedBox(height: 16),
              Text(
                'No requests found',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try changing the search text or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    StaffRequestState state,
    StaffRequestNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF0F5F3),
                ),
                headingTextStyle: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: const TextStyle(color: _textPrimary),
                horizontalMargin: 20,
                columnSpacing: 28,
                columns: const [
                  DataColumn(label: Text('Request')),
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Request details')),
                  DataColumn(label: Text('Submitted')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: state.items
                    .map((request) => _buildDataRow(request, state, notifier))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    StaffRequest request,
    StaffRequestState state,
    StaffRequestNotifier notifier,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            '#${request.requestNumber}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE2F1EC),
                  child: Text(
                    _firstLetter(request.employeeName),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.employeeName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(_buildTypeChip(request)),
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              _requestDetails(request),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(_formatDateTime(request.createdDate))),
        DataCell(_buildStatusChip(request.status)),
        DataCell(_buildActionButtons(request, state, notifier)),
      ],
    );
  }

  Widget _buildRequestCard(
    StaffRequest request,
    StaffRequestState state,
    StaffRequestNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE2F1EC),
                child: Text(
                  _firstLetter(request.employeeName),
                  style: const TextStyle(
                    color: _primary,
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
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request #${request.requestNumber}',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(request.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildTypeChip(request),
          const SizedBox(height: 14),
          Text(
            _requestDetails(request),
            style: const TextStyle(color: _textPrimary, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(request.createdDate),
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (request.status.toUpperCase() == 'PENDING') ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(
                request,
                state,
                notifier,
                compact: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    StaffRequest request,
    StaffRequestState state,
    StaffRequestNotifier notifier, {
    bool compact = false,
  }) {
    if (request.status.toUpperCase() != 'PENDING') {
      return const Text(
        'Processed',
        style: TextStyle(color: _textSecondary, fontSize: 13),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isBusy = state.isProcessingRequest(request);
    final isRejecting = state.isProcessingStatus(request, 'REJECTED');
    final isApproving = state.isProcessingStatus(request, 'APPROVED');

    final rejectButton = SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: isBusy
            ? null
            : () => _confirmAndUpdateStatus(request, 'REJECTED', notifier),
        icon: isRejecting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.close_rounded, size: 18),
        label: const Text('Reject'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    final approveButton = SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: isBusy
            ? null
            : () => _confirmAndUpdateStatus(request, 'APPROVED', notifier),
        icon: isApproving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.check_rounded, size: 18),
        label: const Text('Approve'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    if (compact) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [rejectButton, approveButton],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [rejectButton, const SizedBox(width: 8), approveButton],
    );
  }

  Future<void> _confirmAndUpdateStatus(
    StaffRequest request,
    String targetStatus,
    StaffRequestNotifier notifier,
  ) async {
    final isApprove = targetStatus == 'APPROVED';
    final actionLabel = isApprove ? 'approve' : 'reject';
    final title = isApprove ? 'Approve request?' : 'Reject request?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            'Are you sure you want to $actionLabel request '
            '#${request.requestNumber} from ${request.employeeName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await notifier.updateRequestStatus(
        request: request,
        status: targetStatus,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request #${request.requestNumber} was '
            '${isApprove ? 'approved' : 'rejected'} successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildTypeChip(StaffRequest request) {
    final isLeave = request.isLeaveRequest;

    final backgroundColor = isLeave
        ? const Color(0xFFE9F2FF)
        : const Color(0xFFF2EBFF);

    final textColor = isLeave
        ? const Color(0xFF175CD3)
        : const Color(0xFF6941C6);

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

  Widget _buildStatusChip(String status) {
    final normalized = status.toUpperCase();

    Color backgroundColor;
    Color textColor;

    switch (normalized) {
      case 'APPROVED':
        backgroundColor = const Color(0xFFE7F6EC);
        textColor = const Color(0xFF16794A);
        break;
      case 'REJECTED':
        backgroundColor = const Color(0xFFFFE9E7);
        textColor = const Color(0xFFB42318);
        break;
      case 'PENDING':
        backgroundColor = const Color(0xFFFFF3D6);
        textColor = const Color(0xFF9A6700);
        break;
      default:
        backgroundColor = const Color(0xFFEEF1F0);
        textColor = _textSecondary;
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

  Widget _buildPagination(
    StaffRequestState state,
    StaffRequestNotifier notifier,
  ) {
    final currentPage = state.totalPages == 0 ? 0 : state.page + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            '${state.totalItems} total requests',
            style: const TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: state.hasPreviousPage && !state.isLoading
                      ? notifier.previousPage
                      : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Page $currentPage of ${state.totalPages}',
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: state.hasNextPage && !state.isLoading
                      ? notifier.nextPage
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _requestDetails(StaffRequest request) {
    final reason = request.reason.trim().isEmpty
        ? 'No reason provided.'
        : request.reason.trim();

    if (!request.isLeaveRequest) {
      return reason;
    }

    final dateRange =
        '${_formatDate(request.startDate)} – ${_formatDate(request.endDate)}';

    final totalDays = request.totalLeaveDays;

    if (totalDays == null) {
      return reason;
    }

    return '$reason\n$dateRange · $totalDays day${totalDays == 1 ? '' : 's'}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not specified';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _firstLetter(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}
