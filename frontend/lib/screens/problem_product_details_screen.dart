import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../models/request.dart';
import '../widgets/bento_card.dart';

class ProblemProductDetailsScreen extends StatelessWidget {
  final RequestItem request;

  const ProblemProductDetailsScreen({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    final sku = request.details['sku'] ?? '';
    final productName = request.details['productName'] ?? 'Unknown Product';
    final issueType = request.details['issueType'] ?? 'Expired / Spoiled';
    final quantity = request.details['quantity'] ?? 0;
    final aisle = request.details['aisle'] ?? '';
    final shelf = request.details['shelf'] ?? '';
    final description = request.details['description'] ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Inventory Issue Details',
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
            // Header Card
            BentoCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.report_problem,
                      color: theme.colorScheme.error,
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
                        Text(
                          request.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Reported: ${DateFormat('MMM dd, yyyy').format(request.submissionDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status, theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Specs Bento Card
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issue Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Product Name', productName),
                  _buildDetailRow(context, 'SKU', sku),
                  const Divider(),
                  _buildDetailRow(context, 'Issue Type', issueType),
                  _buildDetailRow(context, 'Quantity', '$quantity units'),
                  const Divider(),
                  _buildDetailRow(context, 'Location', '$aisle - $shelf'),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Staff Description:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Card
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: request.timeline.length,
                    itemBuilder: (context, index) {
                      final event = request.timeline[index];
                      final isFirst = index == 0;
                      final isLast = index == request.timeline.length - 1;
                      return _buildTimelineItem(context, event, isFirst, isLast);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Manager action to resolve/approve disposal
            if (appState.currentUser.role == UserRole.manager && request.status == RequestStatus.pending)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Approve Spoilage Disposal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Update request status to resolved
                    final reqIndex = appState.requests.indexWhere((r) => r.id == request.id);
                    if (reqIndex != -1) {
                      final updated = appState.requests[reqIndex].copyWith(
                        status: RequestStatus.resolved,
                        timeline: [
                          ...appState.requests[reqIndex].timeline,
                          TimelineEvent(
                            title: 'Disposal Approved',
                            description: 'Approved by ${appState.currentUser.name}',
                            timestamp: DateTime.now(),
                          ),
                          TimelineEvent(
                            title: 'Resolved',
                            description: 'Stock updated in inventory records',
                            timestamp: DateTime.now(),
                          ),
                        ],
                      );
                      appState.updateRequest(updated);

                      // Also adjust inventory counts automatically!
                      final prodIndex = appState.products.indexWhere((p) => p.sku == sku);
                      if (prodIndex != -1) {
                        final currentCount = appState.products[prodIndex].stockCount;
                        final newCount = (currentCount - quantity).clamp(0, 9999).toInt();
                        appState.updateProductStock(sku, newCount);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Spoilage disposal approved. Inventory stock count updated.'),
                          backgroundColor: Color(0xFF00503E),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEvent event, bool isFirst, bool isLast) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? theme.colorScheme.primary : theme.colorScheme.outline,
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
                DateFormat('MMM dd, yyyy - hh:mm a').format(event.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
