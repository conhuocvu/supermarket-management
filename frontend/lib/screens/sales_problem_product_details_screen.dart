import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate problem product (issue report) details, loaded from
/// GET /api/product-reports/{reportNumber}. Rendered inside the shell.
class SalesProblemProductDetailsScreen extends ConsumerStatefulWidget {
  final int reportNumber;

  const SalesProblemProductDetailsScreen(
      {super.key, required this.reportNumber});

  @override
  ConsumerState<SalesProblemProductDetailsScreen> createState() =>
      _SalesProblemProductDetailsScreenState();
}

class _SalesProblemProductDetailsScreenState
    extends ConsumerState<SalesProblemProductDetailsScreen> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = ApiService().fetchMyProductReport(widget.reportNumber);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Problem Product Details',
            breadcrumbs: ['Sales', 'Problem Products', 'Details'],
          );
    });
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go('/sales/problems');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Failed to load report.\n${snapshot.error ?? ''}',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                        onPressed: _goBack, child: const Text('Back')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _reportFuture = ApiService()
                            .fetchMyProductReport(widget.reportNumber);
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final r = snapshot.data!;
        final status = (r['status'] ?? 'PENDING').toString();
        final statusColor = _reportStatusColor(status, theme);
        final createdAt = DateTime.tryParse((r['createdAt'] ?? '').toString());
        final resolvedAt =
            DateTime.tryParse((r['resolvedAt'] ?? '').toString());

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    onPressed: _goBack,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Problem Product Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Header card
              BentoCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.report_problem,
                          color: theme.colorScheme.error),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report #${r['reportNumber']}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${r['productName'] ?? 'Unknown Product'}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (createdAt != null)
                            Text(
                              'Reported: ${DateFormat('MMM dd, yyyy - HH:mm').format(createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _titleCase(status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Issue details card
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
                    _detailRow(theme, 'Product Name',
                        '${r['productName'] ?? '-'}'),
                    _detailRow(theme, 'Barcode', '${r['barcode'] ?? '-'}'),
                    const Divider(),
                    _detailRow(theme, 'Issue Type',
                        _issueLabel('${r['issueType'] ?? '-'}')),
                    if (r['quantity'] != null)
                      _detailRow(
                          theme, 'Quantity', '${_trimNum(r['quantity'])} units'),
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
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (r['description'] ?? '').toString().isEmpty
                            ? 'No description provided.'
                            : '${r['description']}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Timeline card
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
                    _timelineItem(
                      theme,
                      title: 'Report Submitted',
                      description: 'Sent to Stock Controller for review',
                      time: createdAt,
                      isFirst: true,
                      isLast: resolvedAt == null && status == 'PENDING',
                      done: true,
                    ),
                    if (status != 'PENDING')
                      _timelineItem(
                        theme,
                        title: _titleCase(status),
                        description: status == 'APPROVED'
                            ? 'Approved — awaiting stock-out processing'
                            : status == 'REJECTED'
                                ? 'Report was rejected'
                                : 'Status updated',
                        time: resolvedAt,
                        isLast: resolvedAt == null,
                        done: true,
                      ),
                    if (resolvedAt != null)
                      _timelineItem(
                        theme,
                        title: 'Resolved',
                        description: 'Inventory records updated',
                        time: resolvedAt,
                        isLast: true,
                        done: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timelineItem(
    ThemeData theme, {
    required String title,
    required String description,
    DateTime? time,
    bool isFirst = false,
    bool isLast = false,
    bool done = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
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
              Text(title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 4),
              if (time != null)
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(time),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
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

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          Flexible(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _trimNum(dynamic n) {
    final d = double.tryParse(n.toString());
    if (d == null) return n.toString();
    return d.truncateToDouble() == d
        ? d.toInt().toString()
        : d.toStringAsFixed(2);
  }

  String _issueLabel(String type) {
    switch (type) {
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'LOW_STOCK':
        return 'Low Stock';
      case 'EXPIRED':
        return 'Expired';
      case 'DAMAGED':
        return 'Damaged';
      case 'SHORTAGE':
        return 'Missing / Shortage';
      case 'OTHER':
        return 'Other';
      default:
        return type;
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Color _reportStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'PENDING':
        return theme.colorScheme.secondary;
      case 'APPROVED':
      case 'RESOLVED':
        return theme.colorScheme.primary;
      case 'REJECTED':
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
