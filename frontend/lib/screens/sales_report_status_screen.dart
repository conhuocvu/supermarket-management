import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/shell_layout_provider.dart';
import '../services/api_service.dart';
import '../widgets/bento_card.dart';

/// Sales Associate report status screen, backed by /api/product-reports.
/// Two tabs: inventory issue reports and product update suggestions.
/// Tapping a row opens the matching detail screen.
class SalesReportStatusScreen extends ConsumerStatefulWidget {
  const SalesReportStatusScreen({super.key});

  @override
  ConsumerState<SalesReportStatusScreen> createState() =>
      _SalesReportStatusScreenState();
}

class _SalesReportStatusScreenState
    extends ConsumerState<SalesReportStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reportsFuture = ApiService().fetchMyProductReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _reportsFuture = ApiService().fetchMyProductReports());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.read(shellLayoutProvider.notifier).update(
          title: 'Request & Report Status',
          breadcrumbs: ['Sales', 'Report Status'],
        );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load reports.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];
          final issues = all
              .where((r) => r['reportType'] == 'INVENTORY_ISSUE')
              .toList();
          final suggestions = all
              .where((r) => r['reportType'] == 'UPDATE_SUGGESTION')
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: MediaQuery.of(context).size.width < 700,
                tabAlignment: MediaQuery.of(context).size.width < 700
                    ? TabAlignment.start
                    : TabAlignment.fill,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3.0,
                tabs: [
                  Tab(text: 'Issue Reports (${issues.length})'),
                  Tab(text: 'Update Suggestions (${suggestions.length})'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(context, issues, isSuggestion: false),
                    _buildList(context, suggestions, isSuggestion: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> list,
      {required bool isSuggestion}) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuggestion
                  ? Icons.edit_note_outlined
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isSuggestion
                  ? 'No update suggestions submitted yet.'
                  : 'No issue reports submitted yet.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final r = list[index];
          final status = (r['status'] ?? 'PENDING').toString();
          final statusColor = _statusColor(status, theme);
          final createdAt =
              DateTime.tryParse((r['createdAt'] ?? '').toString());
          final typeColor = isSuggestion
              ? theme.colorScheme.primary
              : theme.colorScheme.error;

          return BentoCard(
            margin: const EdgeInsets.only(bottom: 12.0),
            onTap: () async {
              final route = isSuggestion
                  ? '/sales/reports/suggestions/${r['reportNumber']}'
                  : '/sales/problems/${r['reportNumber']}';
              await context.push(route);
              if (!mounted) return;
              _reload();
            },
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuggestion ? Icons.edit_note : Icons.report_problem,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${r['reportNumber']}'
                        '${r['barcode'] != null ? ' • ${r['barcode']}' : ''}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r['productName'] ?? 'Unknown Product'}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isSuggestion
                            ? _shorten('${r['description'] ?? ''}')
                            : '${_issueLabel('${r['issueType'] ?? ''}')}'
                                '${r['quantity'] != null ? ' • ${_trimNum(r['quantity'])} units' : ''}'
                                '${createdAt != null ? ' • ${DateFormat('MMM dd, yyyy').format(createdAt)}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _titleCase(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }

  String _shorten(String s) => s.length > 60 ? '${s.substring(0, 57)}...' : s;

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
