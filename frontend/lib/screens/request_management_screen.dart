import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_request.dart';
import '../providers/staff_request_provider.dart';
import '../widgets/request_management/request_error_banner.dart';
import '../widgets/request_management/request_management_content.dart';
import '../widgets/request_management/request_management_filters.dart';
import '../widgets/request_management/request_management_header.dart';
import '../widgets/request_management/request_management_pagination.dart';

class RequestManagementScreen extends ConsumerStatefulWidget {
  const RequestManagementScreen({super.key});

  @override
  ConsumerState<RequestManagementScreen> createState() =>
      _RequestManagementScreenState();
}

class _RequestManagementScreenState
    extends ConsumerState<RequestManagementScreen> {
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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RequestManagementHeader(
                    isCompact: isCompact,
                    isLoading: state.isLoading,
                    onRefresh: notifier.refresh,
                  ),
                  const SizedBox(height: 20),
                  RequestManagementFilters(
                    searchController: _searchController,
                    state: state,
                    onKeywordChanged: notifier.updateKeyword,
                    onClearSearch: () => _clearSearch(notifier),
                    onRequestTypeSelected: notifier.updateRequestType,
                    onStatusSelected: notifier.updateStatus,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    RequestErrorBanner(
                      message: state.errorMessage!,
                      onRetry: notifier.refresh,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: RequestManagementContent(
                      state: state,
                      isCompact: isCompact,
                      onRefresh: notifier.refresh,
                      onUpdateStatus: (request, status) =>
                          _confirmAndUpdateStatus(request, status, notifier),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RequestManagementPagination(
                    state: state,
                    onPreviousPage: notifier.previousPage,
                    onNextPage: notifier.nextPage,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _clearSearch(StaffRequestNotifier notifier) {
    _searchController.clear();
    notifier.updateKeyword('');
    setState(() {});
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
}
