import 'package:flutter/material.dart';

import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';
import 'staff_request_card.dart';
import 'staff_request_table.dart';

class RequestManagementContent extends StatelessWidget {
  final StaffRequestState state;
  final bool isCompact;
  final Future<void> Function() onRefresh;
  final Future<void> Function(StaffRequest, String) onUpdateStatus;

  const RequestManagementContent({
    super.key,
    required this.state,
    required this.isCompact,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    if (isCompact) {
      return RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final request = state.items[index];
            final seqNum = state.totalItems - (state.page * state.size + index);
            return StaffRequestCard(
              request: request,
              state: state,
              seqNum: seqNum,
              onUpdateStatus: onUpdateStatus,
            );
          },
        ),
      );
    }

    return StaffRequestTable(
      state: state,
      onRefresh: onRefresh,
      onUpdateStatus: onUpdateStatus,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No requests found',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try changing the search text or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
