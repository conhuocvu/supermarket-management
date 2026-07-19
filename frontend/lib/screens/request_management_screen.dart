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
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surface;
  Color get _border => Theme.of(context).colorScheme.outlineVariant;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;

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
          side: BorderSide(color: _border),
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
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _primary, width: 1.5),
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
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
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
      return Center(child: CircularProgressIndicator(color: _primary));
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'No requests found',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                headingTextStyle: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: TextStyle(color: _textPrimary),
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    _firstLetter(request.employeeName),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  _firstLetter(request.employeeName),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Request #${request.requestNumber}',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
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
            style: TextStyle(color: _textPrimary, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(request.createdDate),
                style: TextStyle(color: _textSecondary, fontSize: 13),
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
      return Text(
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

  Widget _buildStatusChip(String status) {
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
            style: TextStyle(
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
                style: TextStyle(
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
