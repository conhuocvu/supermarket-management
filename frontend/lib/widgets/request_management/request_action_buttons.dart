import 'package:flutter/material.dart';

import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';
import 'clearance_detail_dialog.dart';
import 'purchase_request_detail_dialog.dart';

class RequestActionButtons extends StatelessWidget {
  final StaffRequest request;
  final StaffRequestState state;
  final bool compact;
  final Future<void> Function(StaffRequest, String) onUpdateStatus;

  const RequestActionButtons({
    super.key,
    required this.request,
    required this.state,
    required this.onUpdateStatus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (request.status.toUpperCase() != 'PENDING') {
      return Text(
        'Processed',
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      );
    }

    final isBusy = state.isProcessingRequest(request);
    final isRejecting = state.isProcessingStatus(request, 'REJECTED');
    final isApproving = state.isProcessingStatus(request, 'APPROVED');

    final isAdjustable = request.isClearanceRequest || request.isPurchaseRequest;

    final adjustButton = isAdjustable
        ? SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: isBusy
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => request.isClearanceRequest
                            ? ClearanceDetailDialog(request: request)
                            : PurchaseRequestDetailDialog(request: request),
                      );
                    },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Adjust'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    final rejectButton = SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : () => onUpdateStatus(request, 'REJECTED'),
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
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );

    final approveButton = SizedBox(
      height: 40,
      child: FilledButton.icon(
        onPressed: isBusy ? null : () => onUpdateStatus(request, 'APPROVED'),
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
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (isAdjustable) adjustButton,
          rejectButton,
          approveButton,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAdjustable) ...[
          adjustButton,
          const SizedBox(width: 8),
        ],
        rejectButton,
        const SizedBox(width: 8),
        approveButton,
      ],
    );
  }
}
