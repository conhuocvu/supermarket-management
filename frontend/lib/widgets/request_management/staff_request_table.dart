import 'package:flutter/material.dart';

import '../../models/staff_request.dart';
import '../../providers/staff_request_provider.dart';
import 'request_action_buttons.dart';
import 'request_chips.dart';
import 'request_management_formatters.dart';

class StaffRequestTable extends StatelessWidget {
  final StaffRequestState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function(StaffRequest, String) onUpdateStatus;

  const StaffRequestTable({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest,
                ),
                headingTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                dataTextStyle: TextStyle(color: colorScheme.onSurface),
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
                rows: state.items.map((request) {
                  return _buildDataRow(context, request);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, StaffRequest request) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    employeeInitial(request.employeeName),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
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
        DataCell(RequestTypeChip(request: request)),
        DataCell(
          SizedBox(
            width: 280,
            child: Text(
              requestDetails(request),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(formatRequestDateTime(request.createdDate))),
        DataCell(RequestStatusChip(status: request.status)),
        DataCell(
          RequestActionButtons(
            request: request,
            state: state,
            onUpdateStatus: onUpdateStatus,
          ),
        ),
      ],
    );
  }
}
