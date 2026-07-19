import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate product update suggestion details, loaded from
/// GET /api/product-reports/{reportNumber}. Rendered inside the shell.
class SalesSuggestionDetailScreen extends ConsumerStatefulWidget {
  final int reportNumber;

  const SalesSuggestionDetailScreen({super.key, required this.reportNumber});

  @override
  ConsumerState<SalesSuggestionDetailScreen> createState() =>
      _SalesSuggestionDetailScreenState();
}

class _SalesSuggestionDetailScreenState
    extends ConsumerState<SalesSuggestionDetailScreen> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = ApiService().fetchMyProductReport(widget.reportNumber);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellLayoutProvider.notifier).update(
            title: 'Suggestion Details',
            breadcrumbs: ['Sales', 'Report Status', 'Suggestion'],
          );
    });
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go('/sales/reports');

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
                  'Failed to load suggestion.\n${snapshot.error ?? ''}',
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
        final statusColor = _statusColor(status, theme);
        final createdAt = DateTime.tryParse((r['createdAt'] ?? '').toString());
        final resolvedAt =
            DateTime.tryParse((r['resolvedAt'] ?? '').toString());
        final suggestion = _parseSuggestion('${r['description'] ?? ''}');

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
                      'Update Suggestion Details',
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
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.edit_note, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Suggestion #${r['reportNumber']}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${r['productName'] ?? 'Unknown Product'}',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (createdAt != null)
                            Text(
                              'Submitted: ${DateFormat('MMM dd, yyyy - HH:mm').format(createdAt)}',
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
              // Suggested changes card
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested Changes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(theme, 'Product', '${r['productName'] ?? '-'}'),
                    _detailRow(theme, 'Barcode', '${r['barcode'] ?? '-'}'),
                    const Divider(),
                    if (suggestion.name != null)
                      _detailRow(theme, 'Suggested Name', suggestion.name!),
                    if (suggestion.price != null)
                      _detailRow(
                          theme, 'Suggested Price', '${suggestion.price} đ'),
                    if (suggestion.name == null && suggestion.price == null)
                      _detailRow(theme, 'Changes', 'See reason below'),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Reason:',
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
                        suggestion.reason ?? 'No reason provided.',
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
                      title: 'Suggestion Submitted',
                      description: 'Sent to Manager for review',
                      time: createdAt,
                      isLast: status == 'PENDING',
                    ),
                    if (status != 'PENDING')
                      _timelineItem(
                        theme,
                        title: _titleCase(status),
                        description: status == 'APPROVED'
                            ? 'Manager approved the suggestion'
                            : status == 'REJECTED'
                                ? 'Manager rejected the suggestion'
                                : 'Status updated',
                        time: resolvedAt,
                        isLast: true,
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

  ({String? name, String? price, String? reason}) _parseSuggestion(
      String description) {
    // Description format written by the backend:
    // "Name: X; Selling price: Y; Reason: Z"
    String? name, price, reason;
    final nameMatch = RegExp(r'Name:\s*([^;]+)').firstMatch(description);
    if (nameMatch != null) name = nameMatch.group(1)?.trim();
    final priceMatch =
        RegExp(r'Selling price:\s*([^;]+)').firstMatch(description);
    if (priceMatch != null) price = priceMatch.group(1)?.trim();
    final reasonMatch = RegExp(r'Reason:\s*(.+)$').firstMatch(description);
    if (reasonMatch != null) reason = reasonMatch.group(1)?.trim();
    if (name == null && price == null && reason == null && description.isNotEmpty) {
      reason = description;
    }
    return (name: name, price: price, reason: reason);
  }

  Widget _timelineItem(
    ThemeData theme, {
    required String title,
    required String description,
    DateTime? time,
    bool isLast = false,
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
                color: theme.colorScheme.primary,
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

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Color _statusColor(String status, ThemeData theme) {
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
