import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';
import 'leave_request_detail_screen.dart';
import 'schedule_request_detail_screen.dart';
import 'problem_product_details_screen.dart';
import 'leave_request_form.dart';
import 'schedule_request_form.dart';

class RequestStatusScreen extends StatefulWidget {
  final RequestType? filterType;
  const RequestStatusScreen({Key? key, this.filterType}) : super(key: key);

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Filter by type if provided
    final rawRequests = widget.filterType != null
        ? appState.requests.where((r) => r.type == widget.filterType).toList()
        : appState.requests;

    // Filter requests
    final activeRequests = rawRequests
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.approved)
        .toList();
    final completedRequests = rawRequests
        .where((r) => r.status == RequestStatus.rejected || r.status == RequestStatus.resolved)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen Title + optional Create button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.filterType == RequestType.leave
                  ? 'Leave Requests'
                  : widget.filterType == RequestType.shiftSwap
                      ? 'Schedule Change Requests'
                      : 'Request & Report Status',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (widget.filterType == RequestType.leave)
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Leave Request'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaveRequestForm()),
                  );
                },
              )
            else if (widget.filterType == RequestType.shiftSwap)
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Request Schedule Change'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScheduleRequestForm()),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: 'Active (${activeRequests.length})'),
            Tab(text: 'Completed (${completedRequests.length})'),
          ],
        ),
        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(context, activeRequests, isDesktop),
              _buildRequestsList(context, completedRequests, isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context, List<RequestItem> list, bool isDesktop) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No requests in this category.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return BentoCard(
          margin: const EdgeInsets.only(bottom: 12.0),
          onTap: () {
            if (request.type == RequestType.leave) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LeaveRequestDetailScreen(request: request),
                ),
              );
            } else if (request.type == RequestType.shiftSwap) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleRequestDetailScreen(request: request),
                ),
              );
            } else if (request.type == RequestType.inventoryIssue) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProblemProductDetailsScreen(request: request),
                ),
              );
            } else {
              _showRequestDetailsBottomSheet(context, request);
            }
          },
          child: Row(
            children: [
              // Icon based on type
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getRequestTypeColor(request.type, theme).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRequestTypeIcon(request.type),
                  color: _getRequestTypeColor(request.type, theme),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.id,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Submitted: ${DateFormat('MMM dd, yyyy').format(request.submissionDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              _buildStatusBadge(request.status, theme),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(RequestStatus status, ThemeData theme) {
    Color badgeColor;
    String label;

    switch (status) {
      case RequestStatus.pending:
        badgeColor = theme.colorScheme.secondary;
        label = 'Pending';
        break;
      case RequestStatus.approved:
        badgeColor = theme.colorScheme.primary;
        label = 'Approved';
        break;
      case RequestStatus.rejected:
        badgeColor = theme.colorScheme.error;
        label = 'Rejected';
        break;
      case RequestStatus.resolved:
        badgeColor = theme.colorScheme.primary;
        label = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRequestDetailsBottomSheet(BuildContext context, RequestItem request) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.id, style: theme.textTheme.labelSmall),
                          Text(
                            request.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(request.status, theme),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(request.description, style: theme.textTheme.bodyMedium),
                  const Divider(height: 32),

                  // Spec parameters inside the Request Details
                  Text('Detailed Specifications', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: request.details.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatKey(entry.key),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 32),

                  // Timeline Section
                  Text('Status Tracking History', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: request.timeline.length,
                    itemBuilder: (context, idx) {
                      final event = request.timeline[idx];
                      final isLast = idx == request.timeline.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vertical timeline line & circle indicators
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: event.isCompleted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 48,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  event.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, hh:mm a').format(event.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatKey(String key) {
    // Camel case to human readable spacing
    final result = key.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ' ${m.group(0)}');
    return result[0].toUpperCase() + result.substring(1);
  }

  IconData _getRequestTypeIcon(RequestType type) {
    switch (type) {
      case RequestType.leave:
        return Icons.time_to_leave;
      case RequestType.shiftSwap:
        return Icons.swap_horiz;
      case RequestType.productSuggestion:
        return Icons.edit_note;
      case RequestType.inventoryIssue:
        return Icons.report_problem;
    }
  }

  Color _getRequestTypeColor(RequestType type, ThemeData theme) {
    switch (type) {
      case RequestType.leave:
        return theme.colorScheme.primary;
      case RequestType.shiftSwap:
        return theme.colorScheme.secondary;
      case RequestType.productSuggestion:
        return theme.colorScheme.primary;
      case RequestType.inventoryIssue:
        return theme.colorScheme.error;
    }
  }
}
